defmodule OctosChallenge.Notify.UserEmailTest do
  use OctosChallenge.DataCase, async: true

  alias OctosChallenge.Factory
  alias OctosChallenge.Notify.UserEmail

  import Swoosh.TestAssertions

  describe "notify/1" do
    test "should correctly send the email to a existent user" do
      user = Factory.insert(:user)

      assert :ok = UserEmail.notify(user)

      assert_email_sent(
        from: {"Camera Capture", "no-reply@email.com"},
        to: [{user.name, user.email}],
        subject: "#{user.name}, your camera captured changes"
      )
    end
  end
end
