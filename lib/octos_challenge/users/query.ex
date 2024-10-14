defmodule OctosChallenge.Users.Query do
  @moduledoc """
  Provides functions for querying user data from the database.
  """

  alias OctosChallenge.Repo
  alias OctosChallenge.Users.User

  import Ecto.Query

  @type result() :: %{
          meta: %{
            per_page: integer(),
            page: integer(),
            total: integer(),
            total_pages: integer()
          },
          data: [User.t() | map()]
        }

  @doc """
  Retrieves users based on the given filter parameters.

  ## Params
    - `params`: A keyword list of parameters to filter the users.
      - `:paginate`: If true, returns a paginated result, default is false.
      - `:per_page`: Quantity of items per page, default is 15 (valid only if paginate is true).
      - `:page`: The page number, default is 1 (valid only if paginate is true).
      - `:camera_name`: Returns only users who have cameras that the name matches.
      - `:camera_brand`: Returns only users who have cameras that the brand matches.
      - `:order_by`: Sorts users based on camera name, values ​​can be ASC or DESC.
      - `:only_user_id`: Returns only user IDs, default is false.
      - `:with_cameras`: Returns users and their active cameras, default is false.

  ## Returns
    - A list of `%User{}` structs if pagination is not enabled.
    - A map containing `:meta` and `:data` if pagination is enabled.

  ## Example

      iex> OctosChallenge.Users.Query.get_all_users([camera_brand: "Hikvision"])
      [%User{}, %User{}, ...]

      iex> OctosChallenge.Users.Query.get_all_users([camera_brand: "Hikvision"], paginate: true)
      %{meta: %{total_pages: 2, page: 1, total: 21, per_page: 15}, data: [%User{}, %User{}, ...]}

      iex> OctosChallenge.Users.Query.get_all_users([only_user_id: true])
      [%{user_id: 1}, %{user_id: 2}, ...]
  """

  @spec get_all_users(params :: Access.t()) :: [User.t() | map()] | result()
  def get_all_users(params \\ %{}) do
    {pagination, params} = handle_params(params)

    query = base_query() |> apply_query_params(params)

    if Map.get(pagination, :paginate, false) do
      handle_pagination(query, pagination)
    else
      query |> Repo.all()
    end
  end

  @doc """
  Retrieves a user by their ID.

  ## Params
    - `user_id`: The ID of the user to retrieve.

  ## Returns
    - `{:ok, %User{}}` if the user is found.
    - `{:error, :user_not_found}` if the user does not exist.

  ## Example

      iex> OctosChallenge.Users.Query.get_user(1)
      {:ok, %User{name: "John", email: "john@example.com"}}

      iex> OctosChallenge.Users.Query.get_user(999)
      {:error, :user_not_found}
  """
  @spec get_user(user_id :: integer()) :: {:ok, User.t()} | {:error, :user_not_found}
  def get_user(user_id) do
    User
    |> Repo.get(user_id)
    |> case do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
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
      only_user_id
      with_cameras
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
      as: :c
  end

  defp apply_query_params(queryable, params) when is_map(params) do
    Enum.reduce(params, queryable, &apply_query_params(&2, &1))
  end

  defp apply_query_params(queryable, {:with_cameras, true}) do
    preload(queryable, [c: c], cameras: c)
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

  defp apply_query_params(queryable, {:only_user_id, true}) do
    select(queryable, [u: u], %{user_id: u.id})
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
end
