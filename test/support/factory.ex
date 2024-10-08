defmodule OctosChallenge.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: OctosChallenge.Repo

  alias OctosChallenge.Models.{Camera, User}

  @brand_names ~w(
    Intelbras
    Hikvision
    Giga
    Vivotek
    Positivo
    TP-Link
  )

  def user_factory(attrs \\ %{}) do
    %User{
      name: Map.get(attrs, :name, sequence("user-")),
      email: Map.get(attrs, :email, sequence(:email, &"user-#{&1}@email.com")),
      disconnected_at: Map.get(attrs, :disconnected_at)
    }
  end

  def camera_factory(attrs \\ %{}) do
    brand = Enum.random(@brand_names)

    %Camera{
      name: Map.get(attrs, :name, sequence("camera-#{brand}-")),
      brand: brand,
      is_active: Map.get(attrs, :is_active, true),
      user: Map.get(attrs, :user, fn -> build(:user) end)
    }
  end
end
