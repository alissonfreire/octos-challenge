defmodule OctosChallenge.Users do
  @moduledoc """
  Module responsible for exposing user scope functions
  """
  alias OctosChallenge.Users.CreateUser
  alias OctosChallenge.Users.Query

  defdelegate get_all_users(params \\ %{}), to: Query
  defdelegate get_user(user_id), to: Query
  defdelegate create_user(params), to: CreateUser
  defdelegate create_many_users(param_list, with_cameras \\ false), to: CreateUser
end
