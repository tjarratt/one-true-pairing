defmodule OneTruePairingWeb.Live.PairView do
  # @related [test](test/one_true_pairing_web/live/pairing_live_test.exs)
  use OneTruePairingWeb, :live_view

  alias OneTruePairing.Projects

  defp projects_impl do
    Provider.provide(:project_impl, default: Projects)
  end

  @impl Phoenix.LiveView
  def mount(%{"project_id" => project_id}, _session, socket) do
    everyone = fetch_people(project_id)

    %{
      name: project_name,
      unpaired: unpaired,
      tracks: tracks,
      unavailable: unavailable
    } = projects_impl().load_project(project_id)

    {:ok,
     socket
     |> assign(project_id: project_id)
     |> assign(project_name: project_name)
     |> assign(everyone: everyone)
     |> assign(pairing_list: unpaired |> recalculate_positions())
     |> assign(unavailable_list: unavailable |> recalculate_positions())
     |> assign(tracks: tracks |> recalculate_track_positions())}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>Hey <%= @project_name %>, let's pair today</.header>

    <div class="my-4 flex justify-between">
      <div>
        <.button phx-click="randomize_pairs" background="bg-emerald-500" background_hover="hover:bg-emerald-400">
          Randomize pairs
        </.button>
        <.button phx-click="reset_pairs">
          Reset pairs
        </.button>
      </div>

      <.link navigate={~p"/projects/#{@project_id}/persons"} class="block bg-cyan-300 hover:bg-cyan-200 pt-2 px-4 rounded-lg">
        Manage Team
      </.link>
    </div>

    <div id="pairing_list" class="grid sm:grid-cols-1 md:grid-cols-4 gap-2">
      <.live_component
        id="available"
        module={OneTruePairingWeb.Live.ListComponent}
        list={@pairing_list}
        list_name="available"
        track_id="available"
        group="pairing"
        test_role="unpaired"
        custom_header
      >
        <.sub_header>Unpaired</.sub_header>
      </.live_component>

      <%= for track <- @tracks do %>
        <.live_component
          id={track.id}
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
        list_name="unavailable"
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
    unpaired = socket.assigns.pairing_list
    tracks = socket.assigns.tracks

    state = %{
      project_id: project_id,
      unpaired: unpaired,
      unavailable: socket.assigns.unavailable_list,
      tracks: tracks
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
    moving_from = params["from"]["list_name"]
    moving_to = params["to"]["list_name"]

    person =
      cond do
        moving_from == "available" -> Enum.at(socket.assigns.pairing_list, index)
        moving_from == "unavailable" -> Enum.at(socket.assigns.unavailable_list, index)
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
    tracks
    |> Enum.map(fn %{id: id, people: people, name: name} ->
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

  # # # TODO: push these down a layer
  # it would be nice to have a bounded context that better represents the 
  # actions that we perform on the board, so that the live view does less work

  defp move(_project_id,
         person: %{id: person_id},
         from: same,
         to: same,
         tracks: tracks,
         unavailable: unavailable,
         unpaired: unpaired
       )
       when person_id != 20 do
    # no-op when from and to are the same
    %{
      tracks: tracks,
      unavailable: unavailable,
      unpaired: unpaired
    }
  end

  defp move(_project_id,
         person: person,
         from: from,
         to: to,
         tracks: tracks,
         unavailable: unavailable,
         unpaired: unpaired
       ) do
    track_names = tracks |> Enum.map(& &1.name)

    if from in track_names do
      track = Enum.find(tracks, fn t -> t.name == from end)
      Projects.remove_person_from_track!(track.id, person.id)
    end

    cond do
      to == "available" ->
        Projects.mark_available_to_pair(person.id)

        %{
          tracks: remove_person_from_tracks(tracks, person),
          unavailable: without(unavailable, [person]),
          unpaired: unpaired ++ [person]
        }

      to == "unavailable" ->
        Projects.mark_unavailable_to_pair(person.id)

        %{
          tracks: remove_person_from_tracks(tracks, person),
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

  defp remove_person_from_tracks(tracks, person) do
    Enum.map(tracks, fn track ->
      %{track | people: without(track.people, [person])}
    end)
  end

  # TODO: move this into OTP.Pairing module and test it there
  # live view should no longer need to assert on state of db for allocations
  # or across page loads
  defp decide_pairs(state) do
    %{arrangements: track_assignments} = state = Projects.decide_pairs(state)
    new_tracks = place_in_tracks(track_assignments)

    %{state | tracks: new_tracks}
  end

  defp place_in_tracks(pairings) do
    pairings
    |> Enum.map(fn {track, pair} ->
      Enum.each(pair, &Projects.allocate_person_to_track!(track.id, &1.id))

      %{track | people: pair}
    end)
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
end
