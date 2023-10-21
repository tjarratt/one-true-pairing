defmodule OneTruePairingWeb.Live.PairView do
  use OneTruePairingWeb, :live_view

  alias OneTruePairing.Projects
  alias OneTruePairing.Projects.Project

  def mount(_params, _session, socket) do
    tracks = fetch_tracks()

    form1 = to_form(Projects.change_project(%Project{}))
    form2 = to_form(Projects.change_project(%Project{}))
    form3 = to_form(Projects.change_project(%Project{}))

    {:ok,
     socket
     |> assign(pairing_list: fetch_people())
     |> assign(tracks: tracks)
     |> assign(form1: form1)
     |> assign(form2: form2)
     |> assign(form3: form3)}
  end

  def render(assigns) do
    ~H"""
    <.header>Let's pair today</.header>

    <div>
      <.button phx-click="randomize_pairs" class="my-4">
        Randomize pairs
      </.button>
    </div>

    <div id="pairing_list" class="grid sm:grid-cols-1 md:grid-cols-3 gap-2">
      <.live_component
        id="1"
        module={OneTruePairingWeb.Live.ListComponent}
        list={@pairing_list}
        list_name="Folks"
        form={@form1}
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
    </div>
    """
  end

  def handle_info({:repositioned, params}, socket) do
    IO.inspect(params, label: "==========>")
    {:noreply, socket}
  end

  def handle_event("randomize_pairs", _params, socket) do
    folks = socket.assigns.pairing_list
    {unpaired, pairings} = Projects.assign_pairs(folks)
    new_tracks = place_in_tracks(pairings)

    {:noreply,
     socket
     |> assign(tracks: new_tracks)
     |> assign(pairing_list: unpaired)}
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
