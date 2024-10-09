defmodule OctosChallengeWeb.NotifyController do
  @moduledoc false
  use OctosChallengeWeb, :controller

  alias OctosChallenge.NotifyUserWorker

  @default_camera_brand "Hikvision"

  def index(conn, params) do
    camera_brand = Map.get(params, "camera_brand", @default_camera_brand)

    NotifyUserWorker.new(%{camera_brand: camera_brand}) |> Oban.insert!()

    send_resp(conn, :no_content, "")
  end
end
