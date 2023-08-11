defmodule OneTruePairingWeb.Live.ListComponent do
  use OneTruePairingWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 py-4 rounded-lg">
      <div class="space-y-5 mx-auto max-w-7xl px-4 space-y-4">
        <.header>
          <%= @list_name %>
          <.simple_form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
            <.input field={@form[:name]} type="text" />
              <.button class="align-middle ml-2 mt-2">
                <.icon name="hero-plus" />
              </.button>
          </.simple_form>
        </.header>

        <div id={"#{@id}-items"} phx-hook="Sortable" data-list_id={@id} test_role="list">
          <div :for={item <- @list} id={"#{@id}-#{item.id}"} class="..." data-id={item.id}>
            <div class="flex">
              <button type="button" class="w-10">
                <.icon name="hero-check-circle" class={css_for_hero_check(item)} />
              </button>
              <div class="flex-auto block text-sm leading-6 text-zinc-900">
                <%= item.name %>
              </div>
              <button type="button" class="w-10 -mt-1 flex-none">
                <.icon name="hero-x-mark" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("reposition", params, socket) do
    # TOOD: handle the repositioning logic with our list
    IO.inspect(params, label: "Component Reposition event ahoy")

    {:noreply, socket}
  end

  defp css_for_hero_check(item) do
    if item.status == :completed do
      "w-7 h-7 bg-green-600"
    else
      "w-7 h-7 bg-gray-300"
    end
  end
end