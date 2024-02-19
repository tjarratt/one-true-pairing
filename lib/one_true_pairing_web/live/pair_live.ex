defmodule OneTruePairingWeb.Live.PairView do
  # @related [test](test/one_true_pairing_web/live/pairing_live_test.exs)
  use OneTruePairingWeb, :live_view

  alias OneTruePairing.Projects

  def mount(%{"project_id" => project_id}, _session, socket) do
    everyone = fetch_people(project_id)
    tracks = fetch_tracks(project_id: project_id)

    {:ok,
     socket
     |> assign(project_id: project_id)
     |> assign(everyone: everyone)
     |> assign(pairing_list: everyone)
     |> assign(unavailable_list: [])
     |> assign(tracks: tracks)}
  end

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

  def handle_event("repositioned", params, socket) do
    handle_info({:repositioned, params}, socket)
  end

  def handle_event("save", params, socket) do
    handle_info({:save, params}, socket)
  end

  def handle_event("randomize_pairs", _params, %{assigns: %{project_id: project_id}} = socket) do
    folks = socket.assigns.everyone -- socket.assigns.unavailable_list
    tracks = socket.assigns.tracks

    state = %{
      unpaired: folks,
      unavailable: socket.assigns.unavailable_list,
      arrangements: [],
      tracks: Enum.map(tracks, & &1.name)
    }

    new_state = Projects.decide_pairs(state)
    new_tracks = place_in_tracks(project_id, Map.get(new_state, :arrangements))

    {:noreply,
     socket
     |> assign(tracks: new_tracks)
     |> assign(pairing_list: Map.get(new_state, :unpaired))}
  end

  def handle_event("reset_pairs", _params, %{assigns: %{project_id: project_id}} = socket) do
    pairing_list =
      fetch_people(project_id)
      |> without(socket.assigns.unavailable_list)

    {:noreply,
     socket
     |> assign(pairing_list: pairing_list)
     |> assign(tracks: fetch_tracks(project_id: project_id))}
  end

  def handle_info({:renamed, _params}, socket) do
    {:noreply, socket}
  end

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
    index = String.to_integer(params["id"])
    tracks = socket.assigns.tracks
    track_names = tracks |> Enum.map(& &1.name)
    moving_from = params["from"]["list_id"]
    moving_to = params["to"]["list_id"]

    person =
      cond do
        moving_from == "available" -> Enum.at(socket.assigns.pairing_list, index)
        moving_from in track_names -> extract_person_from_tracks(tracks, moving_from, index)
      end

    socket =
      cond do
        moving_to == "unavailable" ->
          socket
          |> assign(:unavailable_list, recalculate_positions(socket.assigns.unavailable_list ++ [person]))
          |> assign(:pairing_list, recalculate_positions(socket.assigns.pairing_list -- [person]))

        moving_to in track_names ->
          socket
          |> assign(:tracks, move_person_to(tracks, moving_to, person))
          |> assign(:unavailable_list, recalculate_positions(socket.assigns.unavailable_list -- [person]))
          |> assign(:pairing_list, recalculate_positions(socket.assigns.pairing_list -- [person]))
      end

    {:noreply, socket}
  end

  defp extract_person_from_tracks(tracks, track_name, person_index) do
    # take person at index from track with name
    tracks
    |> Enum.find(fn track -> track.name == track_name end)
    |> then(& &1.people)
    |> Enum.at(person_index)
  end

  defp move_person_to(tracks, track_name, person) do
    tracks
    |> Enum.map(fn %{id: id, people: people, name: name} ->
      if name == track_name do
        %{id: id, people: recalculate_positions(people ++ [person]), name: name}
      else
        %{id: id, people: recalculate_positions(people -- [person]), name: name}
      end
    end)
  end

  defp update_track_title!(track, new_title) do
    Projects.get_track!(track.id)
    |> Projects.update_track_title!(new_title)

    Map.put(track, :name, new_title)
  end

  defp without(everyone, unavailable) do
    unavailable_names = Enum.map(unavailable, & &1.name)

    Enum.reject(everyone, fn person -> person.name in unavailable_names end)
  end

  defp recalculate_positions(list) do
    list
    |> Enum.map(& &1.name)
    |> Enum.with_index()
    |> Enum.map(fn {name, idx} -> %{name: name, id: idx, position: idx} end)
  end

  defp fetch_tracks(project_id: project_id) do
    Projects.tracks_for(project_id: project_id)
    |> Enum.map(fn track -> %{people: [], id: track.id, name: track.title} end)
  end

  defp fetch_people(project_id) do
    Projects.persons_for(project_id: project_id)
    |> Enum.map(fn person -> person.name end)
    |> Enum.with_index()
    |> Enum.map(fn {name, idx} -> %{name: name, id: idx, position: idx} end)
  end

  defp place_in_tracks(project_id, pairings) do
    tracks = fetch_tracks(project_id: project_id)

    Enum.zip(pairings, tracks)
    |> Enum.map(fn {pair, track_info} -> %{track_info | people: pair} end)
  end
end
