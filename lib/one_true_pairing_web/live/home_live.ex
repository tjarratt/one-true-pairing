defmodule OneTruePairingWeb.Live.HomeView do
  # @related [test](test/one_true_pairing_web/live/home_live_test.exs)
  use OneTruePairingWeb, :live_view

  alias OneTruePairing.Projects

  def render(assigns) do
    ~H"""
    <.header>
      Who's pairing with whom today?
      <:actions>
        <.link href={~p"/projects/new"}>
          <.button>New Project</.button>
        </.link>
      </:actions>
    </.header>

    <.table id="projects" rows={@projects} row_click={&JS.navigate(~p"/projects/#{&1}/pairing")}>
      <:col :let={project} label="Project"><%= project.name %></:col>
    </.table>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, projects: Projects.list_projects())}
  end
end
