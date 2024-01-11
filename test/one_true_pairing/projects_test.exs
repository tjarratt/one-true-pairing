defmodule OneTruePairing.ProjectsTest do
  use OneTruePairing.DataCase

  alias OneTruePairing.Projects

  describe "stuff that isn't crud" do
    test "getting the people for a given project" do
      people = Projects.people_for(project: "nrg") |> Enum.sort()

      assert Enum.member?(people, "Andrew")
      assert Enum.member?(people, "Freja")
      assert Enum.member?(people, "Ronaldo")
      assert Enum.member?(people, "Hitalo")
      assert Enum.member?(people, "Alicia")
    end

    test "getting tracks for a project" do
      tracks = Projects.tracks_for(project: "nrg") |> Enum.sort()

      assert Enum.member?(tracks, "Track 1")
      assert Enum.member?(tracks, "Track 2")
    end
  end

  describe "projects" do
    alias OneTruePairing.Projects.Project

    import OneTruePairing.ProjectsFixtures

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

  describe "people" do
    alias OneTruePairing.Projects.Person

    import OneTruePairing.ProjectsFixtures

    @invalid_attrs %{name: nil}

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
end
