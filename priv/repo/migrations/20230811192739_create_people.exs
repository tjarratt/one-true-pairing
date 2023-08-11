defmodule OneTruePairing.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :string
      add :project_id, references(:projects, on_delete: :nothing)

      timestamps()
    end

    create index(:people, [:project_id])
  end
end
