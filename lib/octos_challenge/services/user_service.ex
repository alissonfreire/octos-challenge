defmodule OctosChallenge.UserService do
  @moduledoc """
  Module responsible for performing operations on camera users such as
  searching and inserting into the database
  """

  alias OctosChallenge.Models.Camera
  alias OctosChallenge.Models.User
  alias OctosChallenge.Repo

  import Ecto.Query

  @spec get_all_users(params :: map()) :: [User.t()]
  def get_all_users(params \\ %{}) do
    base_query()
    |> apply_query_params(params)
    |> Repo.all()
  end

  defp base_query do
    from u in User,
      as: :u,
      left_join: c in assoc(u, :cameras),
      on: c.is_active == true,
      as: :c,
      preload: [cameras: c]
  end

  defp apply_query_params(queryable, params) when is_map(params) do
    Enum.reduce(params, queryable, &apply_query_params(&2, &1))
  end

  defp apply_query_params(queryable, {"camera_name", camera_name}) do
    where(queryable, [c: c], ilike(c.name, ^"%#{camera_name}%"))
  end

  defp apply_query_params(queryable, {"camera_brand", camera_brand}) do
    where(queryable, [c: c], ilike(c.brand, ^"%#{camera_brand}%"))
  end

  defp apply_query_params(queryable, {"order_by", order_criteria}) do
    order_criteria = if order_criteria == "DESC", do: :desc, else: :asc
    order_by(queryable, [c: c], [{^order_criteria, c.name}])
  end

  defp apply_query_params(queryable, _params), do: queryable

  @spec create_user(params :: map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(params) do
    params
    |> User.changeset()
    |> Repo.insert()
  end

  @spec create_many_users(list_params :: [map()], with_cameras :: boolean()) :: :ok
  def create_many_users(list_params, with_cameras)

  def create_many_users(list_params, false = _with_cameras) do
    do_create_many_users(list_params)
  end

  def create_many_users(list_params, true = _with_cameras) do
    {users, cameras} =
      Enum.reduce(list_params, {[], %{}}, fn user, {users, cameras} ->
        {
          [Map.delete(user, :cameras)] ++ users,
          Map.update(cameras, user.name, %{name: user.name, cameras: user.cameras}, fn old ->
            Map.put(old, :cameras, old.cameras ++ user.cameras)
          end)
        }
      end)

    Repo.transaction(fn ->
      do_create_many_users(users)

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
    end)

    :ok
  end

  defp do_create_many_users(list_params) do
    Repo.insert_all(User, list_params)

    :ok
  end
end
