defmodule OneTruePairing.Repo.Migrations.RemoveUniquenessConstraintFromTracks do
  use Ecto.Migration

  def change do
    drop unique_index(:tracks, [:project_id, :title])
  end
end
