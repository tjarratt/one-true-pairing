defmodule OneTruePairing.Repo.Migrations.AddIsDeletedToTracksTable do
  use Ecto.Migration

  def change do
    alter table("tracks") do
      add :is_deleted, :boolean, default: false
    end
  end
end
