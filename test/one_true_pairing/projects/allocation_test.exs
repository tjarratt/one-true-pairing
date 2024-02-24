defmodule OneTruePairing.Projects.AllocationTest do
  # @related [impl](lib/one_true_pairing/projects/allocation.ex)

  use OneTruePairing.DataCase, async: true
  alias OneTruePairing.Projects.Allocation
  import OneTruePairing.ProjectsFixtures

  test "changeset is valid when it has everything it needs" do
    person = person_fixture()
    track = track_fixture()

    changeset =
      Allocation.changeset(%{
        person_id: person.id,
        track_id: track.id
      })

    assert changeset_valid?(changeset)

    assert Repo.insert!(changeset)
  end

  test "changeset is invalid if it lacks a person" do
    changeset = Allocation.changeset(%{track_id: 1})

    assert changeset_invalid?(changeset)
  end

  test "changeset is invalid if it lacks a track" do
    changeset = Allocation.changeset(%{person_id: 1})

    assert changeset_invalid?(changeset)
  end
end
