defmodule OctosChallenge.UsersTest do
  use OctosChallenge.DataCase, async: true

  alias OctosChallenge.Users.Camera
  alias OctosChallenge.Users.User

  alias OctosChallenge.Factory
  alias OctosChallenge.Users

  describe "get_all_users/1" do
    test "should return empty list when there are no users" do
      assert [] == Users.get_all_users()
    end

    test "should return all users when no parameter passed" do
      Factory.insert_list(3, :user)

      assert [_ | _] = users = Users.get_all_users()
      assert Enum.count(users) == 3
    end

    test "should only return users who have active cameras" do
      Factory.insert_list(3, :user)
      |> Enum.each(fn user ->
        Enum.each(1..3, fn idx ->
          Factory.insert(:camera, %{user: user, is_active: idx == 3})
        end)
      end)

      assert [_ | _] = users = Users.get_all_users(%{with_cameras: true})

      assert Enum.count(users) == 3

      Enum.each(users, fn user ->
        assert user.name =~ "user-"
        assert Enum.count(user.cameras) == 1
        assert Enum.all?(user.cameras, &(&1.is_active == true))
      end)
    end

    test "should return only users with filtered cameras" do
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

      assert [_ | _] =
               users = Users.get_all_users(%{with_cameras: true, camera_name: "Hikvision"})

      assert Enum.count(users) == 2

      refute Enum.any?(users, &(&1.name == user_2.name))

      Enum.each(users, fn user ->
        assert user.name =~ "user-"
        assert Enum.count(user.cameras) == 1
        assert Enum.all?(user.cameras, &(&1.name =~ "Hikvision"))
      end)
    end

    test "should return users ordered by camera names" do
      Enum.each(1..3, fn idx ->
        user = Factory.insert(:user, %{name: "User - #{idx}"})

        Factory.insert(:camera, %{user: user, name: "Camera - #{4 - idx}"})
      end)

      assert [_ | _] = users = Users.get_all_users(%{with_cameras: true, order_by: "ASC"})

      assert [asc_user_3, asc_user_2, asc_user_1] = users

      assert asc_user_3.name == "User - 3"
      assert Enum.at(asc_user_3.cameras, 0) |> Map.get(:name) == "Camera - 1"

      assert asc_user_2.name == "User - 2"
      assert Enum.at(asc_user_2.cameras, 0) |> Map.get(:name) == "Camera - 2"

      assert asc_user_1.name == "User - 1"
      assert Enum.at(asc_user_1.cameras, 0) |> Map.get(:name) == "Camera - 3"

      assert [desc_user_1, desc_user_2, desc_user_3] =
               Users.get_all_users(%{with_cameras: true, order_by: "DESC"})

      assert desc_user_1.name == "User - 1"
      assert Enum.at(desc_user_1.cameras, 0) |> Map.get(:name) == "Camera - 3"

      assert desc_user_2.name == "User - 2"
      assert Enum.at(desc_user_2.cameras, 0) |> Map.get(:name) == "Camera - 2"

      assert desc_user_3.name == "User - 3"
      assert Enum.at(desc_user_3.cameras, 0) |> Map.get(:name) == "Camera - 1"
    end

    test "should return paginated users" do
      Enum.each(1..6, fn idx ->
        user = Factory.insert(:user, %{name: "User - #{idx}"})

        Factory.insert(:camera, %{user: user, name: "Camera - #{idx}"})
      end)

      assert %{meta: %{}, data: [_ | _]} =
               result1 =
               Users.get_all_users(%{
                 with_cameras: true,
                 paginate: true,
                 per_page: 3,
                 order_by: "ASC"
               })

      assert [user_1, user_2, user_3] = result1.data

      assert %{per_page: 3, page: 1, total: 6, total_pages: 2} = result1.meta

      assert user_1.name == "User - 1"
      assert Enum.at(user_1.cameras, 0) |> Map.get(:name) == "Camera - 1"

      assert user_2.name == "User - 2"
      assert Enum.at(user_2.cameras, 0) |> Map.get(:name) == "Camera - 2"

      assert user_3.name == "User - 3"
      assert Enum.at(user_3.cameras, 0) |> Map.get(:name) == "Camera - 3"

      assert %{meta: %{}, data: [_ | _]} =
               result2 =
               Users.get_all_users(%{
                 with_cameras: true,
                 paginate: true,
                 page: 2,
                 per_page: 3,
                 order_by: "ASC"
               })

      assert %{per_page: 3, page: 2, total: 6, total_pages: 2} = result2.meta

      assert [user_4, user_5, user_6] = result2.data

      assert user_4.name == "User - 4"
      assert Enum.at(user_4.cameras, 0) |> Map.get(:name) == "Camera - 4"

      assert user_5.name == "User - 5"
      assert Enum.at(user_5.cameras, 0) |> Map.get(:name) == "Camera - 5"

      assert user_6.name == "User - 6"
      assert Enum.at(user_6.cameras, 0) |> Map.get(:name) == "Camera - 6"
    end
  end

  describe "create_many_users/2" do
    test "should create users with the correct data" do
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      users = [
        %{name: "User - 1", email: "user1@email.com", inserted_at: now, updated_at: now},
        %{name: "User - 2", email: "user2@email.com", inserted_at: now, updated_at: now}
      ]

      assert {:ok, 2} = Users.create_many_users(users)

      assert Repo.all(User) |> Enum.count() == 2
    end

    test "should create users and their cameras" do
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      users = [
        %{
          name: "User - 1",
          email: "user1@email.com",
          inserted_at: now,
          updated_at: now,
          cameras: [
            %{name: "Intelbras", brand: "Intelbras", inserted_at: now, updated_at: now},
            %{name: "Vivotek", brand: "Vivotek", inserted_at: now, updated_at: now}
          ]
        },
        %{
          name: "User - 2",
          email: "user2@email.com",
          inserted_at: now,
          updated_at: now,
          cameras: [%{name: "Hikvision", brand: "Hikvision", inserted_at: now, updated_at: now}]
        }
      ]

      assert {:ok, 2} = Users.create_many_users(users, true)
      assert Repo.all(User) |> Enum.count() == 2
      assert Repo.all(Camera) |> Enum.count() == 3
    end

    test "should return error if data is incorrect" do
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      users = [
        %{name: nil, email: "user1@email.com", inserted_at: now, updated_at: now}
      ]

      assert {:error, _error} = Users.create_many_users(users)

      assert Repo.all(User) |> Enum.empty?()
    end
  end
end
