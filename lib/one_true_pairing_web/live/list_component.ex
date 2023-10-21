defmodule OneTruePairingWeb.Live.ListComponent do
  use OneTruePairingWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 py-4 rounded-lg" test-role={@test_role}>
      <div class="space-y-5 mx-auto px-4 space-y-4">
        <header>
          <.simple_form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
            <.input type="text" test-role="track-name" name={"track-named-#{@list_name}"} value={@list_name} class="text-2xl"/>
          </.simple_form>
        </header>

        <div id={"#{@id}-items"} phx-hook="Sortable" data-list_id={@id} test-role="list" data-group={@group}>
          <div
            :for={item <- @list}
            id={"#{@id}-#{item.id}"}
            class="drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0 m-2 border-2 border-dashed border-slate-300"
            data-id={item.id}
          >
            <div class="flex drag-ghost:opacity-0">
              <.icon name="hero-user-circle" class="w-7 h-7 bg-gray-300 mr-2" />
              <div class="flex-auto block text-sm leading-6 text-zinc-900 text-xl">
                <%= item.name %>
              </div>
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
    IO.inspect(params, label: "reposition =========>")

    {:noreply, socket}
  end

  def handle_event("validate", params, socket) do
    IO.inspect(params, label: "validate ===========>")
    {:noreply, socket}
  end
end
