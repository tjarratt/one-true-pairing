defmodule OneTruePairingWeb.Live.PairView do
  use OneTruePairingWeb, :live_view

  alias OneTruePairing.Projects
  alias OneTruePairing.Projects.Project

  def mount(_params, _session, socket) do
    everyone = fetch_people()
    tracks = fetch_tracks()

    form1 = to_form(Projects.change_project(%Project{}))
    form2 = to_form(Projects.change_project(%Project{}))
    form3 = to_form(Projects.change_project(%Project{}))

    pairing_form = to_form(Projects.change_project(%Project{}))
    unavailable_form = to_form(Projects.change_project(%Project{}))

    {:ok,
     socket
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
        list_name="Available to pair"
        form={@pairing_form}
        group="pairing"
        test_role="unpaired"
      />

      <%= for track <- Map.keys(@tracks) do %>
        <.live_component
          id={track}
          module={OneTruePairingWeb.Live.ListComponent}
          list={@tracks[track][:people]}
          list_name={@tracks[track][:name]}
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
        form={@unavailable_form}
        group="pairing"
        test_role="unavailable"
      />
    </div>
    """
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
          |> assign(:unavailable_list, socket.assigns.unavailable_list ++ [person])
          |> assign(:pairing_list, socket.assigns.pairing_list -- [person])

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("repositioned", params, socket) do
    handle_info({:repositioned, params}, socket)
  end

  def handle_event("randomize_pairs", _params, socket) do
    folks = socket.assigns.everyone -- socket.assigns.unavailable_list
    tracks = socket.assigns.tracks
    {unpaired, pairings} = Projects.assign_pairs(folks, tracks)
    new_tracks = place_in_tracks(pairings)

    {:noreply,
     socket
     |> assign(tracks: new_tracks)
     |> assign(pairing_list: unpaired)}
  end

  def handle_event("reset_pairs", _params, socket) do
    {:noreply,
     socket
     |> assign(pairing_list: fetch_people() -- socket.assigns.unavailable_list)
     |> assign(tracks: fetch_tracks())}
  end

  defp fetch_tracks() do
    Projects.tracks_for(project: "nrg")
    |> Enum.map(fn track -> {track, %{people: [], name: track}} end)
    |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, key, value) end)
  end

  defp fetch_people() do
    Projects.people_for(project: "nrg")
    |> Enum.with_index()
    |> Enum.map(fn {name, idx} -> %{name: name, id: idx, position: idx} end)
  end

  defp place_in_tracks(pairings) do
    tracks = fetch_tracks()

    Enum.zip(pairings, tracks)
    |> Enum.map(fn {pair, {name, track_info}} -> {name, %{track_info | people: pair}} end)
    |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, key, value) end)
  end
end
