defmodule OneTruePairing.Repo.Migrations.AddHasLeftProjectToPersonTable do
  use Ecto.Migration

  def change do
    alter table("people") do
      add :has_left_project, :boolean, default: false
    end
  end
end
