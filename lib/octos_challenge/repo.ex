defmodule OctosChallenge.Repo do
  use Ecto.Repo,
    otp_app: :octos_challenge,
    adapter: Ecto.Adapters.Postgres
end
