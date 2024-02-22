defmodule OneTruePairing.Repo.Migrations.CreateAllocationsTable do
  use Ecto.Migration

  def change do
    create table(:track_allocations) do
      add :person_id, references(:people), null: false
      add :track_id, references(:tracks), null: false

      timestamps()
    end
  end
end
