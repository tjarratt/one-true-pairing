defmodule OneTruePairing.Projects.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field :name, :string
    field :project_id, :id

    timestamps()
  end

  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
