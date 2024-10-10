defmodule OctosChallengeWeb.CameraController do
  @moduledoc false
  use OctosChallengeWeb, :controller

  alias OctosChallenge.UserService

  def index(conn, params) do
    data = UserService.get_all_users(params)

    render(conn, :index, data: data)
  end
end
