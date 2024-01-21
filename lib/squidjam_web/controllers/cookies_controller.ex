defmodule SquidjamWeb.CookiesController do
  use SquidjamWeb, :controller

  @one_day_in_seconds 86_400

  # TODO once i have this done, post on
  # https://elixirforum.com/t/persisting-data-across-liveview-navigation/53971/8
  # my version that informs the server that the cookie has been set

  def put(conn, %{"token" => token}) do
    # TODO use proper salt
    case Phoenix.Token.verify(conn, "cookie", token, max_age: @one_day_in_seconds) do
      {:ok, {key, value}} ->
        conn
        |> fetch_session()
        |> put_session(key, value)
        |> send_resp(:ok, "")

      _ ->
        send_resp(conn, :unauthorized, "")
    end
  end
end
