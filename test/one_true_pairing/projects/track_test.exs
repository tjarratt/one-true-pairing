defmodule OneTruePairing.Projects.TrackTest do
  # @related [test](lib/one_true_pairing/projects/track.ex)
  use OneTruePairing.DataCase, async: true

  import OneTruePairing.ProjectsFixtures

  alias OneTruePairing.Projects.Track

  setup do
    project = project_fixture(name: "Rappin")

    [project: project]
  end

  test "changeset is valid when there is a non-empty title", %{project: project} do
    track = track_fixture(title: "temp", project_id: project.id)
    changeset = Track.changeset(track, %{title: "with MC Hammer"})

    assert changeset_valid?(changeset)
  end

  test "changeset is invalid when the title is missing", %{project: project} do
    changeset = Track.changeset(%Track{}, %{project_id: project.id})

    assert changeset_invalid?(changeset)
  end

  test "changeset is invalid when it would create two tracks for a project with the same title", %{project: project} do
    track_fixture(title: "Please Hammer, don't hurt em", project_id: project.id)

    {:error, changeset} =
      Track.changeset(%Track{}, %{title: "Please Hammer, don't hurt em", project_id: project.id})
      |> OneTruePairing.Repo.insert()

    assert changeset_invalid?(changeset)
  end
end
