defmodule OctosChallengeWeb.NotifyController do
  @moduledoc false
  use OctosChallengeWeb, :controller

  use PhoenixSwagger

  alias OctosChallenge.NotifyUserWorker

  @default_camera_brand "Hikvision"

  swagger_path :index do
    post("/notify-users")
    summary("Notify all users")
    description("Notify all users who have cameras with the provided brand")

    parameters do
      camera_brand(:query, :string, "Camera brand", required: false, example: "Hikvision")
    end

    response(204, "")
  end

  def index(conn, params) do
    camera_brand = Map.get(params, "camera_brand", @default_camera_brand)

    NotifyUserWorker.new(%{camera_brand: camera_brand}) |> Oban.insert!()

    send_resp(conn, :no_content, "")
  end
end
