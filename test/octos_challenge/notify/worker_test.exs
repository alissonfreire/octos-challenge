defmodule OctosChallenge.Notify.WorkerTest do
  use OctosChallenge.DataCase, async: true
  use Oban.Testing, repo: OctosChallenge.Repo

  alias OctosChallenge.Factory
  alias OctosChallenge.Notify.Worker

  import Swoosh.TestAssertions

  describe "perform/1" do
    test "should return error the job if the 'user_id' args is missing" do
      assert {:error, "missing 'user_id' in args"} = perform_job(Worker, %{})

      assert_no_email_sent()
    end

    test "should return error the job if the 'user_id' not exist in the database" do
      assert {:error, "user not found"} = perform_job(Worker, %{user_id: 101})

      assert_no_email_sent()
    end

    test "should correctly send the email to a existent user" do
      user = Factory.insert(:user)

      assert :ok = perform_job(Worker, %{user_id: user.id})

      assert_email_sent(
        from: {"Camera Capture", "no-reply@email.com"},
        to: [{user.name, user.email}],
        subject: "#{user.name}, your camera captured changes"
      )
    end
  end
end
