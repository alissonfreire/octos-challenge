defmodule OctosChallenge.NotifyUserEmail do
  @moduledoc false

  use Phoenix.Swoosh,
    template_root: "lib/octos_challenge_web/templates/emails",
    template_path: "notify_users"

  alias OctosChallenge.Models.User

  @spec notify(user :: User.t()) :: Swoosh.Email.t()
  def notify(%User{} = user) do
    new()
    |> to({user.name, user.email})
    |> from({"Camera Capture", "no-reply@email.com"})
    |> subject("#{user.name}, your camera captured changes")
    |> render_body("notify_users.html", %{user: user})
  end
end
