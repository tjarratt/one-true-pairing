defmodule OneTruePairing.Projects.AllocationTest do
  use OneTruePairing.DataCase, async: true

  alias OneTruePairing.Projects.Allocation

  test "changeset is valid when it has everything it needs" do
    changeset =
      Allocation.changeset(%{
        person: %{name: "Bilbo", project_id: 1},
        project_id: 1
      })

    assert changeset_valid?(changeset)
  end

  test "changeset is invalid if it lacks a person" do
    changeset = Allocation.changeset(%{project_id: 1})

    assert changeset_invalid?(changeset)
  end

  test "changeset is invalid if it lacks a project" do
    changeset = Allocation.changeset(%{person_id: 1})

    assert changeset_invalid?(changeset)
  end
end
