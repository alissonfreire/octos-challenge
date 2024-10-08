defmodule OctosChallenge.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:name, :string)
      add(:email, :string)
      add(:disconnected_at, :utc_datetime, null: true)

      timestamps()
    end
  end
end
