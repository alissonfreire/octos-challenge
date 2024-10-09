defmodule OctosChallengeWeb.NotifyControllerTest do
  use OctosChallengeWeb.ConnCase, async: true
  use Oban.Testing, repo: OctosChallenge.Repo

  alias OctosChallenge.NotifyUserWorker

  describe "/notify-users" do
    test "POST /notify-users should create a notify user job", %{conn: conn} do
      assert [] = all_enqueued(worker: NotifyUserWorker)

      assert conn
             |> post("/notify-users", %{"camera_brand" => "Hikvision"})
             |> response(204)

      assert_enqueued(worker: NotifyUserWorker, args: %{"camera_brand" => "Hikvision"})
    end
  end
end
