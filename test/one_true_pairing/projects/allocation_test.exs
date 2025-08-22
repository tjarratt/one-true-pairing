defmodule OneTruePairing.Projects.AllocationTest do
  # @related [impl](lib/one_true_pairing/projects/allocation.ex)

  use OneTruePairing.DataCase, async: true
  alias OneTruePairing.Projects.Allocation

  import OneTruePairing.ProjectsFixtures
  import Expect
  import Expect.Matchers

  test "changeset is valid when it has everything it needs" do
    person = person_fixture()
    track = track_fixture()

    changeset =
      Allocation.changeset(%{
        person_id: person.id,
        track_id: track.id
      })

    expect(changeset_valid?(changeset), to: be_truthy())

    Repo.insert!(changeset)
    all_allocations = Repo.all(Allocation)

    expect(all_allocations, to: have_length(1))
  end

  test "changeset is invalid if it lacks a person" do
    changeset = Allocation.changeset(%{track_id: 1})

    expect(changeset_invalid?(changeset), to: be_truthy())
  end

  test "changeset is invalid if it lacks a track" do
    changeset = Allocation.changeset(%{person_id: 1})

    expect(changeset_invalid?(changeset), to: be_truthy())
  end
end
