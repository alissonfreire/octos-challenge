defmodule OctosChallenge.Seeder do
  @moduledoc """
  Module responsible for populating the database, specifically the `users` and `cameras` tables.
  """

  alias OctosChallenge.UserService

  @user_names ~w(Pedro Tiago João André Felipe Mateus Tomé Bartolomeu Judas Simão Zelote Tadeu)
  @brand_names ~w(Intelbras Hikvision Giga Vivotek Positivo TP-Link)

  @chunk_size 50
  @magic_number 13

  def seed(opts \\ []) do
    max_users = Keyword.get(opts, :max_users, 1000)

    1..max_users
    |> Task.async_stream(&build_user_params/1)
    |> Stream.map(fn {:ok, param} -> param end)
    |> Stream.chunk_every(@chunk_size)
    |> Stream.each(&UserService.create_many_users(&1, true))
    |> Stream.run()
  end

  defp build_user_params(idx) do
    now = NaiveDateTime.utc_now()
    full_idx = "#{idx}#{now.microsecond |> elem(0)}"

    now = now |> NaiveDateTime.truncate(:second)

    user_name = "#{Enum.random(@user_names)} #{Enum.random(@user_names)}"

    email =
      (user_name
       |> String.replace(" ", "_")
       |> String.downcase()
       |> String.normalize(:nfd)
       |> String.replace(~r/[^a-z-\s_]/u, "")) <> "#{full_idx}@email.com"

    disconnected_at = if disconnected?(idx), do: now, else: nil

    %{
      name: "#{user_name} - #{full_idx}",
      email: email,
      inserted_at: now,
      updated_at: now,
      disconnected_at: disconnected_at,
      cameras: build_camera_params(idx, "#{user_name} - #{full_idx}")
    }
  end

  defp build_camera_params(idx, user_name) do
    Enum.map(1..50, fn cam_idx ->
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      camera_brand = Enum.random(@brand_names)

      %{
        name: "#{user_name} #{camera_brand} - #{cam_idx}",
        brand: camera_brand,
        is_active: not disconnected?(idx),
        inserted_at: now,
        updated_at: now
      }
    end)
  end

  defp disconnected?(idx) do
    rem(idx, @magic_number) == 0
  end
end
