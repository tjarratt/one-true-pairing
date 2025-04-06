defmodule OneTruePairingWeb.Live.ListComponent do
  use OneTruePairingWeb, :live_component

  @doc """
  Renders a list of items that can be dragged from one list to another
  """

  attr :custom_header, :boolean, default: false
  attr :can_be_deleted, :boolean, default: true
  slot :inner_block, required: false

  def render(assigns) do
    ~H"""
    <div class="relative bg-gray-100 py-4 rounded-lg select-none" test-role={@test_role} test-track-name={@list_name}>
      <button
        :if={@can_be_deleted}
        id={"delete-#{@id}"}
        phx-click="delete_track"
        phx-value-id={@track_id}
        class="absolute top-2 right-2 leading-none text-gray-500 hover:text-gray-400"
      >
        <.icon name="hero-x-circle" />
      </button>

      <div class="space-y-5 mx-auto px-4 space-y-4 h-full">
        <div class="flex justify-center">
          <%= if @custom_header do %>
            <div class="mb-1">
              <%= render_slot(@inner_block) %>
            </div>
          <% else %>
            <header>
              <.simple_form for={nil} phx-change="save" phx-submit="save" phx-target={@myself}>
                <.input
                  type="text"
                  test-role="track-name"
                  name={"track_id_#{@track_id}"}
                  value={@list_name}
                  class="text-2xl"
                  phx-debounce
                />
              </.simple_form>
            </header>
          <% end %>
        </div>

        <div
          id={"#{@id}-items"}
          phx-hook="Sortable"
          data-list_id={@id}
          data-list_name={@list_name}
          test-role="list"
          data-group={@group}
          class="min-h-40 h-full"
        >
          <div
            :for={item <- @list}
            id={"#{@id}-#{item.id}"}
            class="drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0 m-2 border-2 border-dashed border-slate-300"
            data-id={item.id}
            test-index={item.position}
          >
            <div class="flex drag-ghost:opacity-0 min-h-10 align-bottom">
              <.icon name="hero-user-circle" class="w-10 h-10 bg-gray-300 mr-2" />
              <div class="flex-auto block text-sm leading-10 text-zinc-900 text-xl">
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
    send(self(), {:repositioned, params})

    {:noreply, socket}
  end

  def handle_event("validate", params, socket) do
    send(self(), {:renamed, params})

    {:noreply, socket}
  end

  def handle_event("save", params, socket) do
    send(self(), {:save, params})

    {:noreply, socket}
  end
end
