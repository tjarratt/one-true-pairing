defmodule OneTruePairingWeb.Live.PairView do
  use OneTruePairingWeb, :live_view

  alias OneTruePairing.Projects
  alias OneTruePairing.Projects.Project

  def mount(_params, _session, socket) do
    list = [
      %{name: "Alice", id: 1, position: 1, status: :in_progress},
      %{name: "Bob", id: 2, position: 2, status: :in_progress},
      %{name: "Carol", id: 3, position: 3, status: :in_progress}
    ]

    form = to_form(Projects.change_project(%Project{}))

    {:ok,
     socket
     |> assign(pairing_list: list)
     |> assign(form: form)}
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
        form={@form}
      />
    </div>
    """
  end

  def handle_info({:repositioned, params}, socket) do
    IO.inspect(params, label: "==========>")
    {:noreply, socket}
  end
end
