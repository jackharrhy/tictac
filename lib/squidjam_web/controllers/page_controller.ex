defmodule SquidjamWeb.PageController do
  use SquidjamWeb, :controller

  def game(conn, _params) do
    render(conn, :game)
  end
end
