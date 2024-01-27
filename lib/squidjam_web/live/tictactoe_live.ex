defmodule SquidjamWeb.TictactoeLive do
  use SquidjamWeb, :live_view

  alias Squidjam.TictactoeServer
  alias Squidjam.TictactoeSupervisor

  def handle_info(%{event: :game_updated, payload: %{game: game}}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:clear_flash, level}, socket) do
    {:noreply, clear_flash(socket, Atom.to_string(level))}
  end

  def handle_info({:put_temporary_flash, level, message}, socket) do
    {:noreply, put_temporary_flash(socket, level, message)}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full h-full flex items-center justify-center flex-col">
      <%= if @game.state == :setup and is_nil(@player) do %>
        <button phx-click="join-game" class="p-2 mb-4 border border-1 border-black">
          join game
        </button>
      <% end %>

      <%= case @game.state do %>
        <% :setup -> %>
          waiting for another player to join...
        <% :active -> %>
          game in progress
        <% :finished -> %>
          finished, result: <%= @game.result %>
      <% end %>

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
    </div>
    """
  end

  def handle_event("join-game", _, socket) do
    %{game: game, player: nil} = socket.assigns

    {:noreply, add_self_to_game(socket, game.slug, game)}
  end

  def handle_event("cell-click", %{"row-index" => row_index, "cell-index" => cell_index}, socket) do
    row_index = String.to_integer(row_index)
    cell_index = String.to_integer(cell_index)

    %{game: game, player: player} = socket.assigns

    if player == nil do
      {:noreply, put_temporary_flash(socket, :error, "not in the game")}
    else
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
  end

  def add_self_to_game(socket, slug, game) do
    player_name = MnemonicSlugs.generate_slug()

    case TictactoeServer.add_player(slug, player_name) do
      {:ok, player} ->
        socket
        |> assign(game: game, player: player)

      {:error, :game_full} ->
        socket
        |> put_temporary_flash(:error, "game full")
        |> assign(game: game, player: nil)
    end
  end

  def mount(%{"slug" => slug} = params, _session, socket) do
    auto_join = Map.has_key?(params, "join")

    unless TictactoeServer.game_exists?(slug) do
      TictactoeSupervisor.start_game(slug)
    end

    {:ok, game} = TictactoeServer.get_game(slug)

    socket =
      if connected?(socket) do
        :ok = Phoenix.PubSub.subscribe(Squidjam.PubSub, slug)

        if length(game.players) == 0 || auto_join do
          add_self_to_game(socket, slug, game)
        else
          assign(socket, game: game, player: nil)
        end
      else
        assign(socket, game: game, player: nil)
      end

    {:ok, socket}
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
