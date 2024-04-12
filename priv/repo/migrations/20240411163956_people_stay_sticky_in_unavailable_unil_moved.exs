defmodule OneTruePairing.Repo.Migrations.PeopleStayStickyInUnavailableUnilMoved do
  use Ecto.Migration

  def change do
    alter table("people") do
      add :unavailable, :boolean, default: false
    end
  end
end
