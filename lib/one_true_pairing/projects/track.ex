defmodule OneTruePairing.Projects.Track do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tracks" do
    field :title, :string
    field :project_id, :id

    timestamps()
  end

  def changeset(track, attrs) do
    track
    |> cast(attrs, [:title, :project_id])
    |> validate_required([:title, :project_id])
  end
end
