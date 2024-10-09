defmodule OctosChallenge.UserService do
  @moduledoc false

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
end
