defmodule OneTruePairingWeb.Live.PairView do
  use OneTruePairingWeb, :live_view

  alias OneTruePairing.Projects
  alias OneTruePairing.Projects.Project

  def mount(_params, _session, socket) do
    people = [
      %{name: "Konstantinos", id: 1, position: 1},
      %{name: "Freja", id: 2, position: 2},
      %{name: "Jon", id: 3, position: 3},
      %{name: "Andrew", id: 4, position: 4},
      %{name: "Tim", id: 5, position: 5},
      %{name: "Sarah", id: 6, position: 6}
    ]

    tracks = %{
      sso: %{people: [], name: "sso"},
      filters: %{people: [], name: "filters"}
    }

    form1 = to_form(Projects.change_project(%Project{}))
    form2 = to_form(Projects.change_project(%Project{}))
    form3 = to_form(Projects.change_project(%Project{}))

    {:ok,
     socket
     |> assign(pairing_list: people)
     |> assign(tracks: tracks)
     |> assign(form1: form1)
     |> assign(form2: form2)
     |> assign(form3: form3)}
  end

  def render(assigns) do
    ~H"""
    <h2>Let's pair today</h2>
    <div id="pairing_list" class="grid sm:grid-cols-1 md:grid-cols-3 gap-2">
      <.live_component
        id="1"
        module={OneTruePairingWeb.Live.ListComponent}
        list={@pairing_list}
        list_name="Folks"
        form={@form1}
        group="pairing"
        test_role="people"
      />

      <.live_component
        id="2"
        module={OneTruePairingWeb.Live.ListComponent}
        list={@tracks[:sso][:people]}
        list_name={@tracks[:sso][:name]}
        form={@form2}
        group="pairing"
        test_role="track-sso"
      />

      <.live_component
        id="3"
        module={OneTruePairingWeb.Live.ListComponent}
        list={@tracks[:filters][:people]}
        list_name={@tracks[:filters][:name]}
        form={@form3}
        group="pairing"
        test_role="track-filters"
      />
    </div>
    """
  end

  def handle_info({:repositioned, params}, socket) do
    IO.inspect(params, label: "==========>")
    {:noreply, socket}
  end
end
