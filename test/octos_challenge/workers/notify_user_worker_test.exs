defmodule OctosChallenge.NotifyUserWorkerTest do
  use OctosChallenge.DataCase, async: true
  use Oban.Testing, repo: OctosChallenge.Repo

  alias OctosChallenge.Factory
  alias OctosChallenge.NotifyUserWorker

  import Swoosh.TestAssertions

  # setup :set_swoosh_global

  describe "perform/1" do
    test "should cancel the job if the 'camera_brand' args is missing" do
      assert {:cancel, "missing 'camera_brand' in args"} = perform_job(NotifyUserWorker, %{})
    end

    test "should correctly send the email to a user with a camera that matched" do
      user = Factory.insert(:user)

      camera = Factory.insert(:camera, %{user: user, brand: "Hikvision"})

      assert :ok = perform_job(NotifyUserWorker, %{camera_brand: camera.brand})

      assert_emails_sent([
        %{
          from: {"Camera Capture", "no-reply@email.com"},
          to: [{user.name, user.email}],
          subject: "#{user.name}, your camera captured changes"
        }
      ])
    end

    test "should not send the email to a user with an unmatched camera" do
      user = Factory.insert(:user)

      _camera = Factory.insert(:camera, %{user: user, brand: "Hikvision"})

      assert :ok = perform_job(NotifyUserWorker, %{camera_brand: "Intelbras"})

      assert_no_email_sent()
    end

    test "should correctly send the email to all users with cameras that match" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)

      camera1 = Factory.insert(:camera, %{user: user1, brand: "Hikvision"})
      _camera2 = Factory.insert(:camera, %{user: user2, brand: "Hikvision"})

      assert :ok = perform_job(NotifyUserWorker, %{camera_brand: camera1.brand})

      assert_emails_sent([
        %{
          from: {"Camera Capture", "no-reply@email.com"},
          to: [{user1.name, user1.email}],
          subject: "#{user1.name}, your camera captured changes"
        },
        %{
          from: {"Camera Capture", "no-reply@email.com"},
          to: [{user2.name, user2.email}],
          subject: "#{user2.name}, your camera captured changes"
        }
      ])
    end
  end
end
