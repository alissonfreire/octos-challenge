defmodule OctosChallengeWeb.NotifyControllerTest do
  use OctosChallengeWeb.ConnCase, async: true
  use Oban.Testing, repo: OctosChallenge.Repo

  alias OctosChallenge.Factory
  alias OctosChallenge.Notify.Worker

  describe "/notify-users" do
    test "POST /notify-users should not create jobs if not users", %{conn: conn} do
      assert conn
             |> post("/notify-users", %{"camera_brand" => "Hikvision"})
             |> response(204)

      assert [] = all_enqueued(worker: Worker)
    end

    test "POST /notify-users should create a notify user job", %{conn: conn} do
      user = Factory.insert(:user)
      Factory.insert(:camera, user: user, brand: "Hikvision")

      assert [] = all_enqueued(worker: Worker)

      assert conn
             |> post("/notify-users", %{"camera_brand" => "Hikvision"})
             |> response(204)

      assert_enqueued(worker: Worker, args: %{"user_id" => user.id})
    end

    test "POST /notify-users should create jobs for only users who have a camera with a given brand",
         %{conn: conn} do
      user1 = Factory.insert(:user)
      Factory.insert(:camera, user: user1, brand: "Hikvision")

      user2 = Factory.insert(:user)
      Factory.insert(:camera, user: user2, brand: "Intelbras")

      assert [] = all_enqueued(worker: Worker)

      assert conn
             |> post("/notify-users", %{"camera_brand" => "Hikvision"})
             |> response(204)

      assert_enqueued(worker: Worker, args: %{"user_id" => user1.id})

      refute_enqueued(worker: Worker, args: %{"user_id" => user2.id})
    end
  end
end
