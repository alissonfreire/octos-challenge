defmodule OctosChallengeWeb.CameraControllerTest do
  use OctosChallengeWeb.ConnCase, async: true

  alias OctosChallenge.Factory

  describe "/cameras" do
    test "GET /cameras should return an empty list when there are no users", %{conn: conn} do
      resp = conn |> get("/cameras") |> json_response(200)

      assert resp == %{"data" => []}
    end

    test "GET /cameras should return a list with valid users", %{conn: conn} do
      Factory.insert_list(3, :user)
      |> Enum.each(fn user ->
        Factory.insert_list(3, :camera, %{user: user, is_active: true})
      end)

      resp = conn |> get("/cameras") |> json_response(200)

      assert %{"data" => [_ | _] = users} = resp

      assert Enum.count(users) == 3

      Enum.each(users, fn user ->
        assert user["name"] =~ "user-"
        assert Enum.count(user["cameras"]) == 3
        assert Enum.all?(user["cameras"], &(&1["is_active"] == true))
      end)
    end

    test "GET /cameras should return only active cameras", %{conn: conn} do
      Factory.insert_list(3, :user)
      |> Enum.each(fn user ->
        Enum.each(1..3, fn idx ->
          Factory.insert(:camera, %{user: user, is_active: idx == 3})
        end)
      end)

      resp = conn |> get("/cameras") |> json_response(200)

      assert %{"data" => [_ | _] = users} = resp

      assert Enum.count(users) == 3

      Enum.each(users, fn user ->
        assert user["name"] =~ "user-"
        assert Enum.count(user["cameras"]) == 1
        assert Enum.all?(user["cameras"], &(&1["is_active"] == true))
      end)
    end

    test "GET /cameras should return logged out users with all cameras disabled", %{conn: conn} do
      Factory.insert_list(3, :user, %{disconnected_at: NaiveDateTime.utc_now()})
      |> Enum.each(fn user ->
        Factory.insert(:camera, %{user: user, is_active: false})
      end)

      resp = conn |> get("/cameras") |> json_response(200)

      assert %{"data" => [_ | _] = users} = resp

      assert Enum.count(users) == 3

      Enum.each(users, fn user ->
        assert user["name"] =~ "user-"
        assert Enum.empty?(user["cameras"])
        refute is_nil(user["disconnected_at"])
      end)
    end

    test "GET /cameras should return only filtered cameras", %{conn: conn} do
      [user_1, user_2, user_3] = Factory.insert_list(3, :user)

      Enum.each([user_1, user_3], fn user ->
        Enum.each(1..3, fn idx ->
          name =
            if idx == 3,
              do: "Camera Hikvision - #{user.name}",
              else: Enum.random(~w(Intelbras Giga Vivotek))

          Factory.insert(:camera, %{user: user, name: name})
        end)
      end)

      resp = conn |> get("/cameras", %{"camera_name" => "Hikvision"}) |> json_response(200)

      assert %{"data" => [_ | _] = users} = resp

      assert Enum.count(users) == 2

      refute Enum.any?(users, &(&1["name"] == user_2.name))

      Enum.each(users, fn user ->
        assert user["name"] =~ "user-"
        assert Enum.count(user["cameras"]) == 1
        assert Enum.all?(user["cameras"], &(&1["name"] =~ "Hikvision"))
      end)
    end

    test "GET /cameras should return ordered by camera names", %{conn: conn} do
      Enum.each(1..3, fn idx ->
        user = Factory.insert(:user, %{name: "User - #{idx}"})

        Factory.insert(:camera, %{user: user, name: "Camera - #{4 - idx}"})
      end)

      resp = conn |> get("/cameras", %{"order_by" => "ASC"}) |> json_response(200)

      assert %{"data" => [asc_user_3, asc_user_2, asc_user_1]} = resp

      assert asc_user_3["name"] == "User - 3"
      assert get_in(asc_user_3, ["cameras", Access.at(0), "name"]) == "Camera - 1"

      assert asc_user_2["name"] == "User - 2"
      assert get_in(asc_user_2, ["cameras", Access.at(0), "name"]) == "Camera - 2"

      assert asc_user_1["name"] == "User - 1"
      assert get_in(asc_user_1, ["cameras", Access.at(0), "name"]) == "Camera - 3"

      resp = conn |> get("/cameras", %{"order_by" => "DESC"}) |> json_response(200)

      assert %{"data" => [desc_user_1, desc_user_2, desc_user_3]} = resp

      assert desc_user_1["name"] == "User - 1"
      assert get_in(desc_user_1, ["cameras", Access.at(0), "name"]) == "Camera - 3"

      assert desc_user_2["name"] == "User - 2"
      assert get_in(desc_user_2, ["cameras", Access.at(0), "name"]) == "Camera - 2"

      assert desc_user_3["name"] == "User - 3"
      assert get_in(desc_user_3, ["cameras", Access.at(0), "name"]) == "Camera - 1"
    end

    test "GET /cameras should return paginated users", %{conn: conn} do
      Enum.each(1..6, fn idx ->
        user = Factory.insert(:user, %{name: "User - #{idx}"})

        Factory.insert(:camera, %{user: user, name: "Camera - #{idx}"})
      end)

      resp =
        conn
        |> get("/cameras", %{"paginate" => true, "per_page" => 3, "order_by" => "ASC"})
        |> json_response(200)

      assert %{"meta" => %{"per_page" => 3, "page" => 1, "total" => 6, "total_pages" => 2}} = resp
      assert %{"data" => [asc_user_1, asc_user_2, asc_user_3]} = resp

      assert asc_user_1["name"] == "User - 1"
      assert get_in(asc_user_1, ["cameras", Access.at(0), "name"]) == "Camera - 1"

      assert asc_user_2["name"] == "User - 2"
      assert get_in(asc_user_2, ["cameras", Access.at(0), "name"]) == "Camera - 2"

      assert asc_user_3["name"] == "User - 3"
      assert get_in(asc_user_3, ["cameras", Access.at(0), "name"]) == "Camera - 3"

      resp =
        conn
        |> get("/cameras", %{
          "paginate" => true,
          "page" => 2,
          "per_page" => 3,
          "order_by" => "ASC"
        })
        |> json_response(200)

      assert %{"meta" => %{"per_page" => 3, "page" => 2, "total" => 6, "total_pages" => 2}} = resp
      assert %{"data" => [asc_user_4, asc_user_5, asc_user_6]} = resp

      assert asc_user_4["name"] == "User - 4"
      assert get_in(asc_user_4, ["cameras", Access.at(0), "name"]) == "Camera - 4"

      assert asc_user_5["name"] == "User - 5"
      assert get_in(asc_user_5, ["cameras", Access.at(0), "name"]) == "Camera - 5"

      assert asc_user_6["name"] == "User - 6"
      assert get_in(asc_user_6, ["cameras", Access.at(0), "name"]) == "Camera - 6"
    end
  end
end
