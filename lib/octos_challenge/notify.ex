defmodule OctosChallenge.Notify do
  @moduledoc """
  Handles the queuing of jobs to send notification emails to users.
  """

  alias OctosChallenge.Notify.Worker
  alias OctosChallenge.Users

  @doc """
  Queues jobs to send notification emails to users based on filter parameters.

  ## Params
    - `params`: A keyword list used to filter users in the database.

  ## Returns
    - `:ok` after all jobs are queued.

  ## Example

      iex> OctosChallenge.Notify.enqueue_all_jobs([camera_name: "Hikvision"])
      :ok
  """
  @spec enqueue_all_jobs(params :: map()) :: :ok
  def enqueue_all_jobs(params) do
    params
    |> Map.put(:only_user_id, true)
    |> Users.get_all_users()
    |> Enum.each(&(Worker.new(&1) |> Oban.insert()))
  end
end
