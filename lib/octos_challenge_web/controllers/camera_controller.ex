defmodule OctosChallengeWeb.CameraController do
  @moduledoc false
  use OctosChallengeWeb, :controller

  alias OctosChallenge.UserService

  def index(conn, params) do
    users = UserService.get_all_users(params)

    render(conn, :index, users: users)
  end
end
