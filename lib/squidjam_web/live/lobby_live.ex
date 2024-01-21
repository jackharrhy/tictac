defmodule SquidjamWeb.LobbyLive do
  use SquidjamWeb, :live_view

  alias Squidjam.TictactoeServer
  alias Squidjam.TictactoeSupervisor

  # TODO put into shared helpers dir
  def handle_info({:clear_flash, level}, socket) do
    {:noreply, clear_flash(socket, Atom.to_string(level))}
  end

  def handle_info({:put_temporary_flash, level, message}, socket) do
    {:noreply, put_temporary_flash(socket, level, message)}
  end

  def handle_info({:join_game, attrs}, socket) do
    %{slug: slug, player_name: player_name} = attrs

    TictactoeSupervisor.start_game(slug)

    socket =
      case TictactoeServer.add_player(slug, player_name) do
        {:ok, _player} ->
          socket
          |> assign(:slug, slug)
          |> push_event("setup-cookies", %{
            method: "PUT",
            path: ~p"/api/cookies",
            token:
              Phoenix.Token.sign(
                socket,
                "cookie",
                {"tictactoe", %{slug: slug, player_name: player_name}}
              ),
            context: "player_name"
          })

        {:error, :name_taken} ->
          socket
          |> put_temporary_flash(:error, "name taken")

        {:error, :game_full} ->
          socket
          |> put_temporary_flash(:error, "game full")
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <form
      id="lobby-form"
      phx-hook="CookieListener"
      phx-change="update"
      phx-submit="join-game"
      phx-debounce="250"
      class="flex flex-col gap-4"
    >
      <label>
        name: <input name="player_name" type="text" value={@player_name} />
      </label>
      <label>
        game slug: <input name="slug" type="text" value={@slug} />
        <button type="button" phx-click="generate-code">generate</button>
      </label>
      <button type="submit">join</button>
    </form>
    """
  end

  def handle_event("cookies-setup", "player_name", socket) do
    %{slug: slug} = socket.assigns
    {:noreply, redirect(socket, to: "/tictactoe/#{slug}")}
  end

  def handle_event("update", fields, socket) do
    %{"slug" => slug, "player_name" => player_name} = fields
    {:noreply, assign(socket, slug: slug, player_name: player_name)}
  end

  def handle_event("generate-code", _, socket) do
    {:noreply, assign(socket, slug: MnemonicSlugs.generate_slug())}
  end

  def handle_event("join-game", %{"slug" => slug}, socket) when byte_size(slug) < 2 do
    send(self(), {:put_temporary_flash, :error, "slug must be at least 2 characters long"})
    {:noreply, socket}
  end

  def handle_event("join-game", %{"player_name" => name}, socket) when byte_size(name) < 2 do
    send(self(), {:put_temporary_flash, :error, "name must be at least 2 characters long"})
    {:noreply, socket}
  end

  def handle_event("join-game", fields, socket) do
    %{"slug" => slug, "player_name" => player_name} = fields

    send(
      self(),
      {:join_game,
       %{
         slug: slug,
         player_name: player_name
       }}
    )

    {:noreply, socket}
  end

  def mount(params, _session, socket) do
    slug = Map.get(params, "slug", "sluggy")
    {:ok, assign(socket, player_name: "jack", slug: slug)}
  end

  # TODO put into shared helpers dir
  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
