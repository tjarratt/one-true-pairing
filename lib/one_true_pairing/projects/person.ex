defmodule OneTruePairing.Projects.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field :name, :string
    field :project_id, :id
    field :unavailable, :boolean

    timestamps()
  end

  def changeset(person, attrs) do
    person
    |> cast(attrs, [:name, :project_id, :unavailable])
    |> validate_required([:name, :project_id])
  end
end
