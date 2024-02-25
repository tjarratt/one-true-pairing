defmodule OneTruePairing.Projects.Allocation do
  # @related [test](test/one_true_pairing/projects/allocation_test.exs)

  @moduledoc """
  Represents the allocation of one person to a track of work.

  There should never be one person allocated to a track
  for the same day.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "track_allocations" do
    field :person_id, :id
    belongs_to :track, OneTruePairing.Projects.Track

    timestamps()
  end

  def changeset(allocation \\ %__MODULE__{}, attrs) do
    allocation
    |> cast(attrs, [:track_id, :person_id, :updated_at, :inserted_at])
    |> validate_required(~w[person_id track_id]a)
  end
end
