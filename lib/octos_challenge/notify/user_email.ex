defmodule OctosChallenge.Notify.UserEmail do
  @moduledoc """
  Responsible for creating and sending an email to a user.
  """

  use Phoenix.Swoosh,
    template_root: "lib/octos_challenge_web/templates/emails",
    template_path: "notify_users"

  alias OctosChallenge.Mailer
  alias OctosChallenge.Users.User

  @doc """
  Sends a notification email to the given user.

  ## Params
    - `%User{}`: The user struct to whom the email will be sent.

  ## Returns
    - `:ok` if the email was successfully sent.
    - `{:error, reason}` if the email sending failed.

  ## Example

      iex> OctosChallenge.Users.NotifyUserEmail.notify(%User{name: "John", email: "john@example.com"})
      :ok

      iex> OctosChallenge.Users.NotifyUserEmail.notify(%User{name: "Invalid", email: "invalid"})
      {:error, :invalid_email}
  """
  @spec notify(user :: User.t()) :: :ok
  def notify(%User{} = user) do
    user
    |> render_email()
    |> Mailer.deliver()
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp render_email(user) do
    new()
    |> to({user.name, user.email})
    |> from({"Camera Capture", "no-reply@email.com"})
    |> subject("#{user.name}, your camera captured changes")
    |> render_body("notify_users.html", %{user: user})
  end
end
