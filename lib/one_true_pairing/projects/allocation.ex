defmodule OneTruePairing.Projects.Allocation do
  @moduledoc """
  Represents the allocation of one person to a track of work.

  There should never be one person allocated to a project
  for the same day.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "allocations" do
    has_one :person, OneTruePairing.Projects.Person
    belongs_to :project, OneTruePairing.Projects.Project

    timestamps()
  end

  @required_attrs ~w[project_id]a

  def changeset(allocation \\ %__MODULE__{}, attrs) do
    allocation
    |> cast(attrs, @required_attrs)
    |> cast_assoc(:person)
    |> validate_required(~w[person project_id]a)
  end
end
