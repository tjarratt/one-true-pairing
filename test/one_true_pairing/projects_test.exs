defmodule OneTruePairing.ProjectsTest do
  # @related [impl](lib/one_true_pairing/projects.ex)
  use OneTruePairing.DataCase

  alias OneTruePairing.Projects

  import Expect
  import Expect.Matchers
  import OneTruePairing.ProjectsFixtures

  describe "a new board-based interface" do
    test "loads the current state of the project" do
      project = project_fixture(name: "Simple team")
      [alice, bob, carol] = Enum.map(~w[Alice Bob Carol], &person_fixture(name: &1, project_id: project.id))
      track = track_fixture(title: "Making a Modest Proposal", project_id: project.id)

      result = Projects.load_project(project.id)

      expect(result)
      |> to_equal(%{
        name: "Simple team",
        unavailable: [],
        unpaired: [
          %{name: "Alice", id: alice.id, unavailable: false},
          %{name: "Bob", id: bob.id, unavailable: false},
          %{name: "Carol", id: carol.id, unavailable: false}
        ],
        tracks: [
          %{id: track.id, name: "Making a Modest Proposal", people: []}
        ]
      })
    end

    test "keeps track of track allocations" do
      project = project_fixture(name: "Allocated team")
      [alice, bob, carol] = Enum.map(~w[Alice Bob Carol], &person_fixture(name: &1, project_id: project.id))
      track = track_fixture(title: "Making a Modest Proposal", project_id: project.id)

      Projects.allocate_person_to_track!(track.id, alice.id)

      result = Projects.load_project(project.id)

      expect(result)
      |> to_equal(%{
        name: "Allocated team",
        unavailable: [],
        unpaired: [
          %{name: "Bob", id: bob.id, unavailable: false},
          %{name: "Carol", id: carol.id, unavailable: false}
        ],
        tracks: [
          %{
            id: track.id,
            name: "Making a Modest Proposal",
            people: [%{name: "Alice", id: alice.id, unavailable: false}]
          }
        ]
      })
    end

    test "keeps track of people's availability" do
      project = project_fixture(name: "A Team")
      [alice, bob, carol] = Enum.map(~w[Alice Bob Carol], &person_fixture(name: &1, project_id: project.id))
      track = track_fixture(title: "Making a Modest Proposal", project_id: project.id)

      Projects.allocate_person_to_track!(track.id, alice.id)
      Projects.mark_unavailable_to_pair(carol.id)

      result = Projects.load_project(project.id)

      expect(result)
      |> to_equal(%{
        name: "A Team",
        unavailable: [%{name: "Carol", id: carol.id, unavailable: true}],
        unpaired: [%{name: "Bob", id: bob.id, unavailable: false}],
        tracks: [
          %{
            id: track.id,
            name: "Making a Modest Proposal",
            people: [%{name: "Alice", id: alice.id, unavailable: false}]
          }
        ]
      })
    end

    test "sorts tracks with no name last" do
      project = project_fixture(name: "lots of work, changing all the time")
      Enum.map(~w[Alice], &person_fixture(name: &1, project_id: project.id))

      track_fixture(title: "     ", project_id: project.id)
      track_fixture(title: nil, project_id: project.id)
      track_fixture(title: "Will be first", project_id: project.id)

      project = Projects.load_project(project.id)
      track_names = Enum.map(project.tracks, & &1.name)

      assert ["Will be first", _, _] = track_names
    end

    test "sorts tracks by name ascending" do
      project = project_fixture(name: "lots of work, changing all the time")
      Enum.map(~w[Alice], &person_fixture(name: &1, project_id: project.id))

      track_fixture(title: "third", project_id: project.id)
      track_fixture(title: "second", project_id: project.id)
      track_fixture(title: "first", project_id: project.id)

      project = Projects.load_project(project.id)
      track_names = Enum.map(project.tracks, & &1.name)

      assert ["first", "second", "third"] = track_names
    end
  end

  describe "projects" do
    alias OneTruePairing.Projects.Project
    @invalid_attrs %{name: nil}

    test "list_projects/0 returns all projects" do
      project = project_fixture()

      expect(Projects.list_projects()) |> to_contain(project)
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()

      expect(Projects.get_project!(project.id)) |> to_equal(project)
    end

    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{name: "some name"}

      {:ok, %Project{} = project} = Projects.create_project(valid_attrs)

      expect(project.name) |> to_equal("some name")
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      update_attrs = %{name: "some updated name"}

      {:ok, %Project{} = project} = Projects.update_project(project, update_attrs)

      expect(project.name) |> to_equal("some updated name")
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs)

      expect(Projects.get_project!(project.id)) |> to_equal(project)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()

      {:ok, %Project{}} = Projects.delete_project(project)

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

      {:ok, %Track{} = track} = Projects.create_track(valid_attrs)

      expect(track.title) |> to_equal("coal mining")
      expect(track.project_id) |> to_equal(project.id)
    end

    test "can be fetched given a project" do
      project_a = project_fixture(name: "a")
      project_b = project_fixture(name: "b")

      homepage = track_fixture(title: "homepage", project_id: project_a.id)
      _backoffice = track_fixture(title: "backoffice", project_id: project_b.id)

      tracks = Projects.tracks_for(project_id: project_a.id)

      expect(tracks) |> to_equal([homepage])
    end

    test "can have their title updated" do
      project = project_fixture()
      {:ok, track} = Projects.create_track(%{title: "coal mining", project_id: project.id})

      updated = Projects.update_track_title!(track, "refining vespene gas")

      expect(updated.title) |> to_equal("refining vespene gas")
      expect(Projects.get_track!(track.id).title) |> to_equal("refining vespene gas")
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

      expect(people) |> to_contain(only: alice)
    end

    test "once removed from the project, they are no longer returend by persons_for/1" do
      project = project_fixture(name: "a")

      alice = person_fixture(name: "Alice", project_id: project.id)
      Projects.update_person(alice, %{has_left_project: true})

      people = Projects.persons_for(project_id: project.id, excluding_project_leavers: true)

      expect(people) |> to_be_empty()
    end

    test "marking someone as unavailable sets the flag" do
      project = project_fixture(name: "a")
      alice = person_fixture(name: "Alice", project_id: project.id)

      Projects.mark_unavailable_to_pair(alice.id)

      [person] = Projects.persons_for(project_id: project.id)

      expect(person.name) |> to_equal("Alice")
      expect(person.unavailable) |> to_be_truthy()
    end

    test "marking someone as available removes the flag" do
      project = project_fixture(name: "a")
      alice = person_fixture(name: "Alice", project_id: project.id)

      Projects.mark_unavailable_to_pair(alice.id)
      Projects.mark_available_to_pair(alice.id)

      [person] = Projects.persons_for(project_id: project.id)

      expect(person.name) |> to_equal("Alice")
      refute person.unavailable
    end

    test "list_people/0 returns all people" do
      person = person_fixture()

      expect(Projects.list_people()) |> to_contain(only: person)
    end

    test "get_person!/1 returns the person with given id" do
      person = person_fixture()

      expect(Projects.get_person!(person.id)) |> to_equal(person)
    end

    test "create_person/1 with valid data creates a person" do
      project = project_fixture()
      valid_attrs = %{name: "some name", project_id: project.id}

      {:ok, %Person{} = person} = Projects.create_person(valid_attrs)

      expect(person.name) |> to_equal("some name")
      expect(person.has_left_project) |> to_equal(nil)
    end

    test "create_person/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_person(@invalid_attrs)
    end

    test "updating a person when they have left the team they were on" do
      person = person_fixture()

      {:ok, person} = Projects.update_person(person, %{has_left_project: true})

      expect(person.has_left_project) |> to_equal(true)
    end

    test "update_person/2 with valid data updates the person" do
      person = person_fixture()
      update_attrs = %{name: "some updated name"}

      {:ok, %Person{} = person} = Projects.update_person(person, update_attrs)

      expect(person.name) |> to_equal("some updated name")
    end

    test "update_person/2 with invalid data returns error changeset" do
      person = person_fixture()

      {:error, %Ecto.Changeset{}} = Projects.update_person(person, @invalid_attrs)

      expect(person) |> to_equal(Projects.get_person!(person.id))
    end

    test "delete_person/1 deletes the person" do
      person = person_fixture()

      {:ok, %Person{}} = Projects.delete_person(person)

      assert_raise Ecto.NoResultsError, fn -> Projects.get_person!(person.id) end
    end

    test "delete_person/1 can delete a person that was previously allocated" do
      person = person_fixture(name: "Thom Yorke")
      track = track_fixture(title: "How to Disappear Completely")
      Projects.allocate_person_to_track!(track.id, person.id)

      {:ok, %Person{}} = Projects.delete_person(person)

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

      allocated =
        Projects.allocations_for_track(track.id)
        |> Enum.map(& &1.person_id)

      expect(allocated) |> to_equal([ziggy.id, lady_stardust.id])
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

      allocated =
        Projects.allocations_for_track(track.id)
        |> Enum.map(& &1.person_id)

      expect(allocated) |> to_contain(only: lady_stardust.id)
    end

    test "people can be removed from a track" do
      track = track_fixture(title: "Rockin out")
      ziggy = person_fixture(name: "Ziggy")
      lady_stardust = person_fixture(name: "Lady Stardust")

      Projects.allocate_person_to_track!(track.id, ziggy.id)
      Projects.allocate_person_to_track!(track.id, lady_stardust.id)

      Projects.remove_person_from_track!(track.id, lady_stardust.id)

      allocated =
        Projects.allocations_for_track(track.id)
        |> Enum.map(& &1.person_id)

      expect(allocated) |> to_contain(only: ziggy.id)
    end

    test "removing someone from a track of work preserves allocations from previous days" do
      track = track_fixture(title: "Rockin out")
      ziggy = person_fixture(name: "Ziggy")

      {:ok, now} = DateTime.now("Etc/UTC")
      yesterday = DateTime.add(now, -1, :day)

      # allocate ziggy yesterday
      %Allocation{}
      |> Allocation.changeset(%{track_id: track.id, person_id: ziggy.id, updated_at: yesterday, inserted_at: yesterday})
      |> Repo.insert!()

      Projects.allocate_person_to_track!(track.id, ziggy.id)
      Projects.remove_person_from_track!(track.id, ziggy.id)

      [allocation] = Repo.all(Allocation)

      assert dates_equal?(allocation.inserted_at, yesterday)
      assert dates_equal?(allocation.updated_at, yesterday)
      assert allocation.person_id == ziggy.id
      assert allocation.track_id == track.id
    end

    test "allocating someone to a track removes them from others" do
      daydreaming = track_fixture(title: "Moonage daydream")
      suicide = track_fixture(title: "Rock n' Roll suicide")
      ziggy = person_fixture(name: "Ziggy")

      Projects.allocate_person_to_track!(daydreaming.id, ziggy.id)
      Projects.allocate_person_to_track!(suicide.id, ziggy.id)

      [allocation] = Repo.all(Allocation)

      assert allocation.track_id == suicide.id
    end

    test "can be reset for the current day" do
      track = track_fixture(title: "Rockin out")
      ziggy = person_fixture(name: "Ziggy")

      {:ok, now} = DateTime.now("Etc/UTC")
      yesterday = DateTime.add(now, -1, :day)

      # allocate ziggy yesterday
      %Allocation{}
      |> Allocation.changeset(%{track_id: track.id, person_id: ziggy.id, updated_at: yesterday, inserted_at: yesterday})
      |> Repo.insert!()

      # allocate ziggy again today
      Projects.allocate_person_to_track!(track.id, ziggy.id)

      # reset the project
      Projects.reset_allocations_for_the_day(track.project_id)

      [allocation] = Repo.all(Allocation)

      assert dates_equal?(allocation.inserted_at, yesterday)
      assert dates_equal?(allocation.updated_at, yesterday)
      assert allocation.person_id == ziggy.id
      assert allocation.track_id == track.id
    end
  end

  defp dates_equal?(a, b) do
    a.year == b.year and
      a.month == b.month and
      a.day == b.day
  end
end
