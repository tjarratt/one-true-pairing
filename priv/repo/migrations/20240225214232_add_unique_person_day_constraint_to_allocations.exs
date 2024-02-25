defmodule OneTruePairing.Repo.Migrations.AddUniquePersonDayConstraintToAllocations do
  use Ecto.Migration

  def change do
    execute """
      create unique index person_day_allocation_unique ON track_allocations(person_id, date_trunc('day', updated_at));  
    """
  end
end
