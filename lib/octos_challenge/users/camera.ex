defmodule OctosChallenge.Users.Camera do
  @moduledoc false
  use Ecto.Schema

  alias OctosChallenge.Users.User
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @fields ~w(name brand is_active)a
  @required_fields ~w(name brand)a

  @derive {Jason.Encoder, only: [:name, :brand, :is_active]}
  schema "cameras" do
    field :name, :string
    field :brand, :string
    field :is_active, :boolean, default: true

    belongs_to :user, User

    timestamps()
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end
end
