defmodule OctosChallenge.Models.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias OctosChallenge.Models.Camera

  @type t :: %__MODULE__{}

  @fields ~w(name disconnected_at)a
  @required_fields ~w(name email)a

  @derive {Jason.Encoder, only: [:name, :email, :disconnected_at, :cameras]}

  schema "users" do
    field :name, :string
    field :email, :string
    field :disconnected_at, :utc_datetime

    has_many :cameras, Camera
    timestamps()
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end
end
