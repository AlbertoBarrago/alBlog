defmodule Alblog.Repo do
  use Ecto.Repo,
    otp_app: :alblog,
    adapter: Ecto.Adapters.Postgres
end
