defmodule SquidjamWeb.TictactoeLive do
  use SquidjamWeb, :live_view

  alias Squidjam.TictactoeServer

  def handle_info(%{event: :game_updated, payload: %{game: game}}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  # TODO put into shared helpers dir
  def handle_info({:clear_flash, level}, socket) do
    {:noreply, clear_flash(socket, Atom.to_string(level))}
  end

  def handle_info({:put_temporary_flash, level, message}, socket) do
    {:noreply, put_temporary_flash(socket, level, message)}
  end

  def render(assigns) do
    ~H"""
    <p>you: <%= @player.name %>, <%= @player.mark %></p>
    <p>game slug: <%= @game.slug %>, active: <%= @game.active %>, turn: <%= @game.turn %></p>

    <div class="p-4">
      <%= for {row, row_index} <- Enum.with_index(@game.board) do %>
        <div class="flex">
          <%= for {cell, cell_index} <- Enum.with_index(row) do %>
            <button
              phx-click="cell-click"
              phx-value-row-index={row_index}
              phx-value-cell-index={cell_index}
              class="flex text-3xl items-center justify-center w-16 h-16 border border-2 border-slate-300"
            >
              <%= cell %>
            </button>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("cell-click", %{"row-index" => row_index, "cell-index" => cell_index}, socket) do
    row_index = String.to_integer(row_index)
    cell_index = String.to_integer(cell_index)

    %{game: game, player: player} = socket.assigns

    socket =
      case TictactoeServer.cell_interact(game.slug, player.name, row_index, cell_index) do
        {:ok, _game} ->
          socket

        {:error, error} ->
          # TODO map error atom -> user facing string
          socket
          |> put_temporary_flash(:error, "#{error}")
      end

    {:noreply, socket}
  end

  def mount(_params, session, socket) do
    %{slug: slug, player_name: player_name} = Map.fetch!(session, "tictactoe")

    {:ok, game} = TictactoeServer.get_game(slug)
    {:ok, player} = TictactoeServer.get_player_by_name(slug, player_name)
    # {:ok, _} <- Presence.track(self(), game_id, player_id, %{}),

    :ok = Phoenix.PubSub.subscribe(Squidjam.PubSub, slug)

    socket = socket |> assign(game: game, player: player)

    {:ok, socket}
  end

  # TODO put into shared helpers dir
  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
