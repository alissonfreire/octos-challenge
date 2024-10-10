defmodule OctosChallenge.UserService do
  @moduledoc """
  Module responsible for performing operations on camera users such as
  searching and inserting into the database
  """

  alias OctosChallenge.Models.Camera
  alias OctosChallenge.Models.User
  alias OctosChallenge.Repo

  import Ecto.Query

  @type data() :: %{
          meta: %{
            per_page: integer(),
            page: integer(),
            total: integer(),
            total_pages: integer()
          },
          data: [User.t()]
        }

  @spec get_all_users(params :: map()) :: [User.t()] | data()
  def get_all_users(params \\ %{}) do
    {pagination, params} = handle_params(params)

    query = base_query() |> apply_query_params(params)

    if Map.get(pagination, :paginate, false) do
      handle_pagination(query, pagination)
    else
      query |> Repo.all()
    end
  end

  defp handle_params(params) do
    params_keys = ~w(
      paginate
      per_page
      page
      camera_name
      camera_brand
      order_by
    )a

    params_keys
    |> Enum.reduce({%{}, %{}}, fn param_key, acc ->
      params
      |> get_param_value(param_key)
      |> handle_param(acc, param_key)
    end)
  end

  defp get_param_value(params, param_key) do
    Map.get(params, param_key) || Map.get(params, to_string(param_key))
  end

  defp handle_param(param_value, {pagination, rest_params}, :paginate) do
    {Map.put(pagination, :paginate, param_value in [true, "true"]), rest_params}
  end

  defp handle_param(param_value, {pagination, rest_params}, :per_page) do
    {Map.put(pagination, :per_page, get_integer_value(param_value, 15)), rest_params}
  end

  defp handle_param(param_value, {pagination, rest_params}, :page) do
    {Map.put(pagination, :page, get_integer_value(param_value, 1)), rest_params}
  end

  defp handle_param(param_value, {pagination, rest_params}, param_key) do
    if param_value in [nil, ""] do
      {pagination, rest_params}
    else
      {pagination, Map.put(rest_params, param_key, param_value)}
    end
  end

  defp get_integer_value(nil, default), do: default

  defp get_integer_value(value, default) when is_binary(value) do
    if String.match?(value, ~r/\d/),
      do: String.to_integer(value),
      else: default
  end

  defp get_integer_value(value, _default), do: value

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

  defp apply_query_params(queryable, {:camera_name, camera_name}) do
    where(queryable, [c: c], ilike(c.name, ^"%#{camera_name}%"))
  end

  defp apply_query_params(queryable, {:camera_brand, camera_brand}) do
    where(queryable, [c: c], ilike(c.brand, ^"%#{camera_brand}%"))
  end

  defp apply_query_params(queryable, {:order_by, order_criteria}) do
    order_criteria = if order_criteria == "DESC", do: :desc, else: :asc
    order_by(queryable, [c: c], [{^order_criteria, c.name}])
  end

  defp apply_query_params(queryable, {:limit, limit}) do
    limit(queryable, ^limit)
  end

  defp apply_query_params(queryable, {:offset, offset}) do
    offset(queryable, ^offset)
  end

  defp apply_query_params(queryable, _params), do: queryable

  defp handle_pagination(query, pagination) do
    count = query |> Repo.aggregate(:count)

    page = Map.get(pagination, :page, 1)
    per_page = Map.get(pagination, :per_page, 15)

    offset = (page - 1) * per_page

    result =
      query
      |> apply_query_params(%{limit: per_page, offset: offset})
      |> Repo.all()

    %{
      meta: %{
        per_page: per_page,
        page: page,
        total: count,
        total_pages: div(count, per_page)
      },
      data: result
    }
  end

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
