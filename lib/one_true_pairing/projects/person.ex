defmodule OneTruePairing.Projects.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field :name, :string
    field :project_id, :id
    field :unavailable, :boolean
    field :has_left_project, :boolean

    timestamps()
  end

  def changeset(person, attrs) do
    person
    |> cast(attrs, [:name, :project_id, :unavailable, :has_left_project])
    |> validate_required([:name, :project_id])
  end
end
