defmodule OneTruePairing.Repo do
  use Ecto.Repo,
    otp_app: :one_true_pairing,
    adapter: Ecto.Adapters.Postgres
end
