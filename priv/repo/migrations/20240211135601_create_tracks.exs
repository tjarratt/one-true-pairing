defmodule OneTruePairing.Repo.Migrations.CreateTracks do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add :title, :string
      add :project_id, references(:projects, on_delete: :nothing)

      timestamps()
    end

    create index(:tracks, [:project_id])
  end
end
