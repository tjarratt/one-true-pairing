defmodule OneTruePairingWeb.Live.ExampleView do
  use OneTruePairingWeb, :live_view

  import Phoenix.HTML.Form, only: [select: 4]

  def mount(_params, _session, socket) do
    {:ok, socket 
      |> assign(:message, "What does your banana look like ?")
      |> assign(:ripeness, ["green", "yellow", "brown", "purple"])}
  end

  def render(assigns) do
    ~H"""
    <h1><%= @message %></h1>

    <.form :let={f} for={to_form(%{})} phx-change="choose_ripeness">
      <%= select(f, :ripeness, @ripeness, prompt: @message) %>
    </.form>
    """
  end

  def handle_event("choose_ripeness", params, socket) do
    {:noreply, socket |> assign(:message, message_for(params["ripeness"]))}
  end

  defp message_for(ripeness) do
    case ripeness do
      "green" -> "Whoa, slow down. It's as hard as a rock."
      "yellow" -> "Go ahead. It's delicious !"
      "brown" -> "Easy partner, that banana's seen better days"
      "purple" -> "Where did you get that banana ?"
    end
  end
end
