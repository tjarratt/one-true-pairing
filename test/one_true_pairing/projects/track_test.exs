defmodule OneTruePairing.Projects.TrackTest do
  # @related [test](lib/one_true_pairing/projects/track.ex)
  use OneTruePairing.DataCase, async: true
  use Expect

  import OneTruePairing.ProjectsFixtures,
    only: [
      project_fixture: 0,
      project_fixture: 1,
      track_fixture: 1
    ]

  alias OneTruePairing.Projects.Track

  setup do
    project = project_fixture(name: "Rappin")

    [project: project]
  end

  test "changeset is valid when there is an empty title", %{project: project} do
    track = track_fixture(title: "", project_id: project.id)
    changeset = Track.changeset(track, %{title: ""})

    expect(changeset_valid?(changeset), to: be_truthy())
  end
end
