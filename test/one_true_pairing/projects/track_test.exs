defmodule OneTruePairing.Projects.TrackTest do
  # @related [test](lib/one_true_pairing/projects/track.ex)
  use OneTruePairing.DataCase, async: true

  import OneTruePairing.ProjectsFixtures
  import Expect
  import Expect.Matchers

  alias OneTruePairing.Projects.Track

  setup do
    project = project_fixture(name: "Rappin")

    [project: project]
  end

  test "changeset is valid when there is an empty title", %{project: project} do
    track = track_fixture(title: "", project_id: project.id)
    changeset = Track.changeset(track, %{title: ""})

    expect(changeset_valid?(changeset)) |> to_be_truthy()
  end
end
