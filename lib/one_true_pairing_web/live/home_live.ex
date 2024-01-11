defmodule OneTruePairingWeb.Live.HomeView do
  use OneTruePairingWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>Who's pairing today?</.header>

    <p>🚧 Under construction 🚧</p>
    <p>🚧 Under construction 🚧</p>
    <p>🚧 Under construction 🚧</p>
    <p>🚧 Under construction 🚧</p>

    <p class="absolute bottom-5 left -5">Better go ask Tim how to use this thing until he builds the homepage¯\_(ツ)_/¯</p>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
