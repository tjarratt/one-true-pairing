defmodule OneTruePairingWeb.Live.PairView do
  # @related [test](test/one_true_pairing_web/live/pairing_live_test.exs)
  use OneTruePairingWeb, :live_view

  alias OneTruePairing.Projects
  alias OneTruePairing.Projects.Project

  def mount(%{"project_id" => project_id}, _session, socket) do
    everyone = fetch_people(project_id)
    tracks = fetch_tracks(project_id: project_id)

    form1 = to_form(Projects.change_project(%Project{}))
    form2 = to_form(Projects.change_project(%Project{}))
    form3 = to_form(Projects.change_project(%Project{}))

    pairing_form = to_form(Projects.change_project(%Project{}))
    unavailable_form = to_form(Projects.change_project(%Project{}))

    {:ok,
     socket
     |> assign(project_id: project_id)
     |> assign(everyone: everyone)
     |> assign(pairing_list: everyone)
     |> assign(unavailable_list: [])
     |> assign(tracks: tracks)
     |> assign(pairing_form: pairing_form)
     |> assign(unavailable_form: unavailable_form)
     |> assign(form1: form1)
     |> assign(form2: form2)
     |> assign(form3: form3)}
  end

  def render(assigns) do
    ~H"""
    <.header>Let's pair today</.header>

    <div class="my-4">
      <.button phx-click="randomize_pairs">
        Randomize pairs
      </.button>
      <.button phx-click="reset_pairs">
        Reset pairs
      </.button>
    </div>

    <div id="pairing_list" class="grid sm:grid-cols-1 md:grid-cols-4 gap-2">
      <.live_component
        id="available"
        module={OneTruePairingWeb.Live.ListComponent}
        list={@pairing_list}
        track_id="unpaired"
        list_name="Available to pair"
        form={@pairing_form}
        group="pairing"
        test_role="unpaired"
      />

      <%= for track <- @tracks do %>
        <.live_component
          id={track.name}
          module={OneTruePairingWeb.Live.ListComponent}
          track_id={track.id}
          list={track.people}
          list_name={track.name}
          form={@form2}
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
        form={@unavailable_form}
        group="pairing"
        test_role="unavailable"
      />
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

  def handle_info({:renamed, params}, socket) do
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

    person =
      case params["from"]["list_id"] do
        "available" -> Enum.at(socket.assigns.pairing_list, index)
      end

    socket =
      case params["to"]["list_id"] do
        "unavailable" ->
          socket
          |> assign(:unavailable_list, recalculate_positions(socket.assigns.unavailable_list ++ [person]))
          |> assign(:pairing_list, recalculate_positions(socket.assigns.pairing_list -- [person]))

        _ ->
          socket
      end

    {:noreply, socket}
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
