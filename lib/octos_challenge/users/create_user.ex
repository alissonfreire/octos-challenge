defmodule OctosChallenge.Users.CreateUser do
  @moduledoc """
  Provides functions for managing user creation in the system.

  This module includes:

  - `create_user/1`: Inserts a single user.
  - `create_many_users/2`: Inserts multiple users, with optional related entities.
  """

  alias OctosChallenge.Repo
  alias OctosChallenge.Users.User
  alias OctosChallenge.Users.Camera

  import Ecto.Query

  @doc """
  Inserts a new user into the database.

  ## Params
    - `user_params`: A map with user data.

  ## Returns
    - `{:ok, %User{}}` on success.
    - `{:error, %Ecto.Changeset{}}` on failure.

  ## Examples
      iex> OctosChallenge.Users.CreateUser.create_user(%{name: "John", email: "john@example.com"})
      {:ok, %User{}}

      iex> OctosChallenge.Users.CreateUser.create_user(%{name: "", email: "invalid"})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_user(params :: map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(params) do
    params
    |> User.changeset()
    |> Repo.insert()
  end

  @doc """
  Inserts multiple users into the database.

  ## Params
    - `user_param_list`: A list of maps, each containing user data. Optionally, each user can have related entities like `:cameras`.
    - `with_cameras`: A boolean indicating whether the user parameters include related entities (e.g., `:cameras`).

  ## Returns
    - {`:ok`, num_rows} on success, where `num_rows` is the number of inserted users.
    - `{:error, reason}` on failure

  ## Examples
      iex> users = [%{name: "John", cameras: %{brand: "Hikvision"}}, %{name: "Alice"}]
      iex> OctosChallenge.Users.CreateUser.create_many_users(users, true)
      {:ok, 2}

      iex> users = [%{name: "", cameras: %{brand: "Hikvision"}}, %{name: "Alice"}]
      iex> OctosChallenge.Users.CreateUser.create_many_users(users, true)
      {:error, "invalid user data"}
  """

  @spec create_many_users(param_list :: [map()], with_cameras :: boolean()) ::
          {:ok, integer()} | {:error, any()}
  def create_many_users(param_list, with_cameras)

  def create_many_users(param_list, false = _with_cameras) do
    do_create_many_users(param_list)
  end

  def create_many_users(param_list, true = _with_cameras) do
    {users, cameras} =
      Enum.reduce(param_list, {[], %{}}, fn user, {users, cameras} ->
        {
          [Map.delete(user, :cameras)] ++ users,
          Map.update(cameras, user.name, %{name: user.name, cameras: user.cameras}, fn old ->
            Map.put(old, :cameras, old.cameras ++ user.cameras)
          end)
        }
      end)

    Repo.transaction(fn ->
      try do
        {:ok, num_rows} = do_create_many_users(users)

        user_names = Map.keys(cameras)

        created_users =
          from(u in User, where: u.name in ^user_names, select: {u.name, u.id})
          |> Repo.all()

        Enum.reduce(created_users, [], fn {user_name, user_id}, acc ->
          all_cameras_with_user_ids =
            cameras
            |> Map.get(user_name)
            |> Map.get(:cameras)
            |> Enum.map(&Map.put(&1, :user_id, user_id))

          all_cameras_with_user_ids ++ acc
        end)
        |> then(&Repo.insert_all(Camera, &1))

        {:ok, num_rows}
      rescue
        error ->
          {:error, error}
      end
    end)
    |> case do
      {:ok, result} -> result
      {:error, error} -> error
    end
  end

  defp do_create_many_users(param_list) do
    Repo.insert_all(User, param_list)
    |> case do
      {:error, error} -> error
      {num_rows, _} -> {:ok, num_rows}
    end

  rescue
    error -> {:error, error}
  end
end
