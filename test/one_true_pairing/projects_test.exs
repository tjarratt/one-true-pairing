defmodule OneTruePairing.ProjectsTest do
  # @related [impl](lib/one_true_pairing/projects.ex)
  use OneTruePairing.DataCase
  alias OneTruePairing.Projects
  import OneTruePairing.ProjectsFixtures

  describe "projects" do
    alias OneTruePairing.Projects.Project
    @invalid_attrs %{name: nil}

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Projects.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Projects.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Project{} = project} = Projects.create_project(valid_attrs)
      assert project.name == "some name"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Project{} = project} = Projects.update_project(project, update_attrs)
      assert project.name == "some updated name"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs)
      assert project == Projects.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end

  describe "tracks" do
    alias OneTruePairing.Projects.Track

    test "can be created" do
      project = project_fixture()
      valid_attrs = %{title: "coal mining", project_id: project.id}

      result = Projects.create_track(valid_attrs)

      assert {:ok, %Track{} = track} = result
      assert track.title == "coal mining"
      assert track.project_id == project.id
    end

    test "can be fetched given a project" do
      project_a = project_fixture(name: "a")
      project_b = project_fixture(name: "b")

      homepage = track_fixture(title: "homepage", project_id: project_a.id)
      _backoffice = track_fixture(title: "backoffice", project_id: project_b.id)

      tracks = Projects.tracks_for(project_id: project_a.id)

      assert tracks == [homepage]
    end

    test "can have their title updated" do
      project = project_fixture()
      {:ok, track} = Projects.create_track(%{title: "coal mining", project_id: project.id})

      updated = Projects.update_track_title!(track, "refining vespene gas")

      assert updated.title == "refining vespene gas"
      assert Projects.get_track!(track.id).title == "refining vespene gas"
    end
  end

  describe "people" do
    alias OneTruePairing.Projects.Person

    @invalid_attrs %{name: nil}

    test "fetching the people for a given project" do
      project_a = project_fixture(name: "a")
      project_b = project_fixture(name: "b")

      alice = person_fixture(name: "Alice", project_id: project_a.id)
      _bob = person_fixture(name: "Bob", project_id: project_b.id)

      people = Projects.persons_for(project_id: project_a.id)

      assert people == [alice]
    end

    test "list_people/0 returns all people" do
      person = person_fixture()
      assert Projects.list_people() == [person]
    end

    test "get_person!/1 returns the person with given id" do
      person = person_fixture()
      assert Projects.get_person!(person.id) == person
    end

    test "create_person/1 with valid data creates a person" do
      project = project_fixture()
      valid_attrs = %{name: "some name", project_id: project.id}

      assert {:ok, %Person{} = person} = Projects.create_person(valid_attrs)
      assert person.name == "some name"
    end

    test "create_person/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_person(@invalid_attrs)
    end

    test "update_person/2 with valid data updates the person" do
      person = person_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Person{} = person} = Projects.update_person(person, update_attrs)
      assert person.name == "some updated name"
    end

    test "update_person/2 with invalid data returns error changeset" do
      person = person_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_person(person, @invalid_attrs)
      assert person == Projects.get_person!(person.id)
    end

    test "delete_person/1 deletes the person" do
      person = person_fixture()
      assert {:ok, %Person{}} = Projects.delete_person(person)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_person!(person.id) end
    end

    test "change_person/1 returns a person changeset" do
      person = person_fixture()
      assert %Ecto.Changeset{} = Projects.change_person(person)
    end
  end

  describe "allocations" do
    alias OneTruePairing.Projects.Allocation

    test "people can be allocated to a track" do
      track = track_fixture(title: "Rockin out")
      ziggy = person_fixture(name: "Ziggy")
      lady_stardust = person_fixture(name: "Lady Stardust")

      Projects.allocate_person_to_track!(track.id, ziggy.id)
      Projects.allocate_person_to_track!(track.id, lady_stardust.id)

      allocated = Projects.allocations_for_track(track.id)
      |> Enum.map(&(&1.person_id))

      assert allocated == [ziggy.id, lady_stardust.id]
    end

    test "getting allocations for a track only gives the allocations for today" do
      track = track_fixture(title: "Rockin out")
      ziggy = person_fixture(name: "Ziggy")
      lady_stardust = person_fixture(name: "Lady Stardust")

      {:ok, now} = DateTime.now("Etc/UTC")
      yesterday = DateTime.add(now, -1, :day)

      # allocate ziggy yesterday
      %Allocation{}
      |> Allocation.changeset(%{track_id: track.id, person_id: ziggy.id, updated_at: yesterday, inserted_at: yesterday})
      |> Repo.insert!()

      Projects.allocate_person_to_track!(track.id, lady_stardust.id)

      allocated = Projects.allocations_for_track(track.id)
      |> Enum.map(&(&1.person_id))

      assert allocated == [lady_stardust.id]
    end

    test "people can be removed from a track" do
      track = track_fixture(title: "Rockin out")
      ziggy = person_fixture(name: "Ziggy")
      lady_stardust = person_fixture(name: "Lady Stardust")

      Projects.allocate_person_to_track!(track.id, ziggy.id)
      Projects.allocate_person_to_track!(track.id, lady_stardust.id)

      Projects.remove_person_from_track!(track.id, lady_stardust.id)

      allocated = Projects.allocations_for_track(track.id)
      |> Enum.map(&(&1.person_id))

      assert allocated == [ziggy.id]
    end

    test "removing someone only removes the allocation for today" do
      track = track_fixture(title: "Rockin out")
      ziggy = person_fixture(name: "Ziggy")

      {:ok, now} = DateTime.now("Etc/UTC")
      yesterday = DateTime.add(now, -1, :day)

      # allocate ziggy yesterday
      %Allocation{}
      |> Allocation.changeset(%{track_id: track.id, person_id: ziggy.id, updated_at: yesterday, created_at: yesterday})
      |> Repo.insert!()

      Projects.allocate_person_to_track!(track.id, ziggy.id)
      Projects.remove_person_from_track!(track.id, ziggy.id)

      allocated = Projects.allocations_for_track(track.id)
      |> Enum.map(&(&1.person_id))

      assert allocated == []
    end
  end
end
