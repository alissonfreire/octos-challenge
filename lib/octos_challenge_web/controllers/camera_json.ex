defmodule OctosChallengeWeb.CameraJSON do
  @moduledoc false
  use OctosChallengeWeb, :controller

  @camera_fields ~w(name brand is_active)a

  def index(%{data: %{meta: meta, data: users}}) do
    %{
      meta: meta,
      data: format_users_data(users)
    }
  end

  def index(%{data: users}) do
    %{
      data: format_users_data(users)
    }
  end

  defp format_users_data(users) do
    Enum.map(users, fn u ->
      %{
        name: u.name,
        email: u.email,
        disconnected_at: u.disconnected_at,
        cameras: Enum.map(u.cameras, &Map.take(&1, @camera_fields))
      }
    end)
  end
end
