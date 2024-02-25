defmodule OneTruePairingWeb.Live.PairView do
  # @related [test](test/one_true_pairing_web/live/pairing_live_test.exs)
  use OneTruePairingWeb, :live_view

  alias OneTruePairing.Projects

  @impl Phoenix.LiveView
  def mount(%{"project_id" => project_id}, _session, socket) do
    everyone = fetch_people(project_id)

    %{
      unpaired: unpaired,
      unavailable: unavailable,
      tracks: tracks
    } = load_project(project_id)

    {:ok,
     socket
     |> assign(project_id: project_id)
     |> assign(everyone: everyone)
     |> assign(pairing_list: unpaired |> recalculate_positions())
     |> assign(unavailable_list: unavailable |> recalculate_positions())
     |> assign(tracks: tracks |> recalculate_track_positions())}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>Let's pair today</.header>

    <div class="my-4">
      <.button phx-click="randomize_pairs">Randomize pairs</.button>
      <.button phx-click="reset_pairs">Reset pairs</.button>
    </div>

    <div id="pairing_list" class="grid sm:grid-cols-1 md:grid-cols-4 gap-2">
      <.live_component
        id="available"
        module={OneTruePairingWeb.Live.ListComponent}
        list={@pairing_list}
        list_name="unpaired"
        track_id="unpaired"
        group="pairing"
        test_role="unpaired"
        custom_header
      >
        <.sub_header>Unpaired</.sub_header>
      </.live_component>

      <%= for track <- @tracks do %>
        <.live_component
          id={track.name}
          module={OneTruePairingWeb.Live.ListComponent}
          track_id={track.id}
          list={track.people}
          list_name={track.name}
          group="pairing"
          test_role="track-of-work"
        />
      <% end %>

      <.live_component
        id="unavailable"
        module={OneTruePairingWeb.Live.ListComponent}
        list={@unavailable_list}
        list_name="Unavailable"
        track_id="unavailable"
        test_role="unavailable"
        group="pairing"
        custom_header
      >
        <.sub_header>Unavailable</.sub_header>
      </.live_component>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("repositioned", params, socket) do
    handle_info({:repositioned, params}, socket)
  end

  def handle_event("save", params, socket) do
    handle_info({:save, params}, socket)
  end

  def handle_event("randomize_pairs", _params, %{assigns: %{project_id: project_id}} = socket) do
    folks = without(socket.assigns.everyone, socket.assigns.unavailable_list)
    tracks = socket.assigns.tracks

    state = %{
      project_id: project_id,
      unpaired: folks,
      unavailable: socket.assigns.unavailable_list,
      arrangements: [],
      tracks: Enum.map(tracks, & &1.name)
    }

    %{tracks: new_tracks, unpaired: unpaired} = decide_pairs(state)

    {:noreply,
     socket
     |> assign(tracks: new_tracks |> recalculate_track_positions())
     |> assign(pairing_list: unpaired |> recalculate_positions())}
  end

  def handle_event("reset_pairs", _params, %{assigns: %{project_id: project_id}} = socket) do
    pairing_list =
      fetch_people(project_id)
      |> without(socket.assigns.unavailable_list)

    Projects.reset_allocations_for_the_day(project_id)

    {:noreply,
     socket
     |> assign(pairing_list: pairing_list |> recalculate_positions())
     |> assign(tracks: fetch_tracks(project_id: project_id))}
  end

  @impl Phoenix.LiveView
  def handle_info({:renamed, _params}, socket) do
    {:noreply, socket}
  end

  @doc """
  Handles the submit event for the name of tracks.

  This is triggered as the user types the name of a track, or presses enter when the
  track input element has focus.
  """
  def handle_info({:save, params}, socket) do
    target = params |> Map.keys() |> Enum.find(&String.starts_with?(&1, "track_id_"))

    ["track", "id", id] = String.split(target, "_")

    id = String.to_integer(id)
    new_title = Map.get(params, target)

    tracks =
      socket.assigns.tracks
      |> Enum.map(fn track ->
        if track.id == id do
          update_track_title!(track, new_title)
        else
          track
        end
      end)

    {:noreply, socket |> assign(:tracks, tracks)}
  end

  def handle_info({:repositioned, params}, socket) do
    project_id = socket.assigns.project_id
    index = params["old"]
    tracks = socket.assigns.tracks
    track_names = tracks |> Enum.map(& &1.name)
    moving_from = params["from"]["list_id"]
    moving_to = params["to"]["list_id"]

    person =
      cond do
        moving_from == "available" -> Enum.at(socket.assigns.pairing_list, index)
        moving_from in track_names -> extract_person_from_tracks(tracks, moving_from, index)
      end

    %{
      unpaired: unpaired,
      unavailable: unavailable,
      tracks: tracks
    } =
      move(project_id,
        person: person,
        from: moving_from,
        to: moving_to,
        tracks: tracks,
        unavailable: socket.assigns.unavailable_list,
        unpaired: socket.assigns.pairing_list
      )

    {:noreply,
     socket
     |> assign(:unavailable_list, recalculate_positions(unavailable))
     |> assign(:pairing_list, recalculate_positions(unpaired))
     |> assign(:tracks, recalculate_track_positions(tracks))}
  end

  # # # private functions

  defp recalculate_track_positions(tracks) do
    Enum.map(tracks, fn %{id: id, people: people, name: name} ->
      %{id: id, people: recalculate_positions(people), name: name}
    end)
  end

  defp recalculate_positions(list) do
    list
    |> Enum.with_index()
    |> Enum.map(fn {thing, index} -> %{name: thing.name, id: thing.id, position: index} end)
  end

  defp fetch_tracks(project_id: project_id) do
    Projects.tracks_for(project_id: project_id)
    |> Enum.map(fn track -> %{people: [], id: track.id, name: track.title} end)
  end

  defp fetch_people(project_id) do
    Projects.persons_for(project_id: project_id)
    |> Enum.with_index()
    |> Enum.map(fn {person, index} -> %{name: person.name, id: person.id, position: index} end)
  end

  # finds a person at a given index within the named track
  defp extract_person_from_tracks(tracks, track_name, person_index) do
    tracks
    |> Enum.find(fn track -> track.name == track_name end)
    |> then(& &1.people)
    |> Enum.at(person_index)
  end

  defp update_track_title!(track, new_title) do
    Projects.get_track!(track.id)
    |> Projects.update_track_title!(new_title)

    Map.put(track, :name, new_title)
  end

  # # # push down a layer

  defp move(_project_id,
         person: person,
         from: _from,
         to: to,
         tracks: tracks,
         unavailable: unavailable,
         unpaired: unpaired
       ) do
    track_names = tracks |> Enum.map(& &1.name)

    cond do
      to == "unavailable" ->
        %{
          tracks: tracks,
          unavailable: unavailable ++ [person],
          unpaired: without(unpaired, [person])
        }

      to in track_names ->
        %{
          tracks: move_person_to(tracks, to, person),
          unavailable: without(unavailable, [person]),
          unpaired: without(unpaired, [person])
        }
    end
  end

  defp decide_pairs(state) do
    new_state = Projects.decide_pairs(state)
    new_tracks = place_in_tracks(Map.get(state, :project_id), Map.get(new_state, :arrangements))

    Map.put(new_state, :tracks, new_tracks)
  end

  defp load_project(project_id) do
    people = fetch_people(project_id)

    tracks =
      fetch_tracks(project_id: project_id)
      |> Enum.map(fn track ->
        allocated_ids = Projects.allocations_for_track(track.id) |> Enum.map(& &1.person_id)
        allocated_people = Enum.filter(people, fn p -> p.id in allocated_ids end)

        %{track | people: allocated_people}
      end)

    all_allocated_ids = tracks |> Enum.flat_map(fn track -> Enum.map(track.people, & &1.id) end)
    unpaired = people |> Enum.filter(fn p -> p.id not in all_allocated_ids end)

    %{
      unpaired: unpaired,
      unavailable: [],
      tracks: tracks
    }
  end

  defp move_person_to(tracks, track_name, person) do
    tracks
    |> Enum.map(fn %{id: id, people: people, name: name} ->
      if name == track_name do
        Projects.allocate_person_to_track!(id, person.id)
        list = (people ++ [person]) |> MapSet.new() |> MapSet.to_list()
        %{id: id, people: list, name: name}
      else
        %{id: id, people: without(people, [person]), name: name}
      end
    end)
  end

  defp without(to_filter, to_remove) do
    names_to_remove = Enum.map(to_remove, & &1.name)

    Enum.reject(to_filter, fn thing -> thing.name in names_to_remove end)
  end

  defp place_in_tracks(project_id, pairings) do
    tracks = fetch_tracks(project_id: project_id)

    Enum.zip(pairings, tracks)
    |> Enum.map(fn {pair, track} ->
      Enum.each(pair, &Projects.allocate_person_to_track!(track.id, &1.id))

      %{track | people: pair}
    end)
  end
end
