defmodule OctosChallenge.Repo.Migrations.AddCamerasTable do
  use Ecto.Migration

  def change do
    create table(:cameras) do
      add(:name, :string)
      add(:brand, :string)
      add(:is_active, :boolean, default: true)

      add(:user_id, references(:users))

      timestamps()
    end
  end
end
