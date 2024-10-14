defmodule OctosChallenge.Notify.Worker do
  @moduledoc false
  use Oban.Worker, queue: :notify_users

  alias OctosChallenge.Notify.UserEmail
  alias OctosChallenge.Users

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id} = _args}) when is_integer(user_id) do
    case Users.get_user(user_id) do
      {:ok, user} -> user |> UserEmail.notify()
      {:error, :user_not_found} -> {:error, "user not found"}
    end
  end

  def perform(%Oban.Job{}) do
    {:error, "missing 'user_id' in args"}
  end
end
