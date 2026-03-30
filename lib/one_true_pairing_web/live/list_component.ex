defmodule OneTruePairingWeb.Live.ListComponent do
  use OneTruePairingWeb, :live_component

  @doc """
  Renders a list of items that can be dragged from one list to another,
  styled as a classic Mac OS window.
  """

  attr :custom_header, :boolean, default: false
  attr :can_be_deleted, :boolean, default: true
  slot :inner_block, required: false

  def render(assigns) do
    ~H"""
    <div class="mac-window" test-role={@test_role} test-track-name={@list_name}>
      <!-- Classic Mac OS title bar -->
      <div class="mac-titlebar">
        <!-- Close box (left) -->
        <%= if @can_be_deleted do %>
          <button
            id={"delete-#{@id}"}
            phx-click="delete_track"
            phx-value-id={@track_id}
            class="mac-close-box"
            title="Close"
          />
        <% else %>
          <div class="mac-close-box-inert" />
        <% end %>
        <!-- Title centered in title bar -->
        <div class="mac-titlebar-center">
          <%= if @custom_header do %>
            <span class="mac-titlebar-label"><%= render_slot(@inner_block) %></span>
          <% else %>
            <.simple_form for={nil} phx-change="save" phx-submit="save" phx-target={@myself} class="mac-titlebar-form">
              <input
                type="text"
                test-role="track-name"
                name={"track_id_#{@track_id}"}
                value={@list_name}
                class="mac-titlebar-input"
                phx-debounce
              />
            </.simple_form>
          <% end %>
        </div>
        <!-- Right spacer to balance close box -->
        <div class="mac-titlebar-spacer" />
      </div>
      <!-- Window body -->
      <div class="mac-window-body">
        <div
          id={"#{@id}-items"}
          phx-hook="Sortable"
          data-list_id={@id}
          data-list_name={@list_name}
          test-role="list"
          data-group={@group}
          class="mac-drop-zone"
        >
          <div
            :for={item <- @list}
            id={"#{@id}-#{item.id}"}
            class="drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:opacity-40 mac-person-item"
            data-id={item.id}
            test-index={item.position}
          >
            <.icon name="hero-user-circle" class="w-5 h-5 flex-shrink-0" />
            <span class="text-xs leading-none truncate"><%= item.name %></span>
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
