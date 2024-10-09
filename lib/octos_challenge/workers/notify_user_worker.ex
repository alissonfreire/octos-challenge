defmodule OctosChallenge.NotifyUserWorker do
  @moduledoc false
  use Oban.Worker, queue: :notify_users

  alias OctosChallenge.Mailer
  alias OctosChallenge.NotifyUserEmail
  alias OctosChallenge.UserService

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"camera_brand" => camera_brand} = _args}) do
    notify_users(%{"camera_brand" => camera_brand})

    :ok
  end

  def perform(%Oban.Job{}) do
    {:cancel, "missing 'camera_brand' in args"}
  end

  defp notify_users(params) do
    params
    |> UserService.get_all_users()
    |> Enum.map(&NotifyUserEmail.notify/1)
    |> Mailer.deliver_many()
  end
end
