defmodule OneTruePairing.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  schema "projects" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
