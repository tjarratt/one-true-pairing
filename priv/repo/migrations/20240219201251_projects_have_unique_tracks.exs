defmodule OneTruePairing.Repo.Migrations.ProjectsHaveUniqueTracks do
  use Ecto.Migration

  def change do
    create unique_index(:tracks, [:project_id, :title])
  end
end
