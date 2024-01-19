defmodule Squidjam.Repo do
  use Ecto.Repo,
    otp_app: :squidjam,
    adapter: Ecto.Adapters.SQLite3
end
