defmodule OneTruePairingWeb.PairingLiveTest do
  # @related [impl](lib/one_true_pairing_web/live/pair_live.ex)
  use OneTruePairingWeb.ConnCase, async: true

  import Expect
  import Expect.Matchers
  import Phoenix.LiveViewTest
  import OneTruePairing.ProjectsFixtures

  setup do
    project = project_fixture(name: "Fellowship")

    track_fixture(title: "1. Taking the hobbits to Eisengard", project_id: project.id)
    track_fixture(title: "2. Boiling potatoes", project_id: project.id)

    person_fixture(project_id: project.id, name: "Andrew")
    person_fixture(project_id: project.id, name: "Freja")
    person_fixture(project_id: project.id, name: "Ronaldo")
    person_fixture(project_id: project.id, name: "Hitalo")
    person_fixture(project_id: project.id, name: "Alicia")

    [project: project]
  end

  require Mocks.HandRolled

  test "testing via dependency injection", %{conn: conn} do
    Injector.inject(
      :project_impl,
      Mocks.HandRolled.new(%{
        name: "Our cool project",
        unavailable: [],
        unpaired: [
          %{id: 1, name: "Andrew"},
          %{id: 2, name: "Freja"},
          %{id: 3, name: "Ronaldo"},
          %{id: 4, name: "Hitalo"},
          %{id: 5, name: "Alicia"}
        ],
        tracks: []
      })
    )

    {:ok, _view, html} = live(conn, ~p"/projects/1/pairing")
    list = select_unpaired(html)

    expect(list) |> to_equal(~w[Andrew Freja Ronaldo Hitalo Alicia])
  end

  describe "the page for determining who pairs with whom" do
    test "has a title", %{conn: conn, project: project} do
      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      header = html |> HtmlQuery.find("h1") |> HtmlQuery.text()

      expect(header) |> to_equal("Hey #{project.name}, let's pair today")
    end

    test "it renders the list of people available to pair", %{conn: conn, project: project} do
      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      list = html |> HtmlQuery.find!("#pairing_list #available-items") |> HtmlQuery.text() |> to_pairs()

      expect(list) |> to_equal(~w[Andrew Freja Ronaldo Hitalo Alicia])
    end

    test "has a link to the page to manage the team", %{conn: conn, project: project} do
      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      links = html |> HtmlQuery.all("a") |> Enum.map(&HtmlQuery.attr(&1, "href"))

      expect(links) |> to_contain("/projects/#{project.id}/persons")
    end
  end

  describe "randomising pairs" do
    test "puts two people in each track of work, and the rest remain unpaired", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      [first_pair, second_pair] =
        html
        |> HtmlQuery.all(test_role: "track-of-work")
        |> Enum.map(&HtmlQuery.text/1)
        |> Enum.map(&to_pairs/1)

      expect(first_pair) |> to_equal(~w[Andrew Freja])

      expect(second_pair) |> to_equal(~w[Ronaldo Hitalo])

      unpaired_folks = select_unpaired(html)
      expect(unpaired_folks) |> to_equal(["Alicia"])
    end

    test "fills in gaps left when someone is pre-assigned to a track", %{conn: conn, project: project} do
      track_fixture(title: "3. Protecting the one ring", project_id: project.id)

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # move Alicia to the first track
      send_person(view, at_index: 4, from: "available", to: "1. Taking the hobbits to Eisengard")

      # move Hitalo to the third track
      html = send_person(view, at_index: 3, from: "available", to: "3. Protecting the one ring")

      [first_pair, second_pair, third_pair] =
        html
        |> HtmlQuery.all(test_role: "track-of-work")
        |> Enum.map(&HtmlQuery.text/1)
        |> Enum.map(&to_pairs/1)

      expect(first_pair) |> to_equal(["Alicia"])
      expect(second_pair) |> to_equal([])
      expect(third_pair) |> to_equal(["Hitalo"])

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      [first_pair, second_pair, third_pair] =
        html
        |> HtmlQuery.all(test_role: "track-of-work")
        |> Enum.map(&HtmlQuery.text/1)
        |> Enum.map(&to_pairs/1)

      expect(first_pair) |> to_equal(["Alicia", "Andrew"])

      expect(second_pair) |> to_equal(["Freja", "Ronaldo"])

      expect(third_pair) |> to_equal(["Hitalo"])

      unpaired_folks = select_unpaired(html)
      expect(unpaired_folks) |> to_be_empty()
    end

    test "pairs can be randomized multiple times", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      view
      |> element("button", "Randomize pairs")
      |> render_click()

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      hobbit_babysitters = people_in_track(html, "1. Taking the hobbits to Eisengard")
      potato_boilers = people_in_track(html, "2. Boiling potatoes")

      expect(hobbit_babysitters) |> to_equal(~w[Andrew Freja])
      expect(potato_boilers) |> to_equal(~w[Ronaldo Hitalo])
    end

    test "does not change the tracks of work", %{conn: conn, project: project} do
      {:ok, view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      rename_nth_track(view, html, 0, "Staring at the One Ring")

      track_titles =
        view
        |> element("button", "Randomize pairs")
        |> render_click()
        |> HtmlQuery.all("[test-role=track-of-work] input")
        |> Enum.map(&HtmlQuery.attr(&1, "value"))

      expect(track_titles) |> to_contain("Staring at the One Ring")
    end

    test "can be reset once randomized", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      view
      |> element("button", "Randomize pairs")
      |> render_click()

      html =
        view
        |> element("button", "Reset pairs")
        |> render_click()

      available = html |> HtmlQuery.find!("#pairing_list #available-items") |> HtmlQuery.text() |> to_pairs()

      expect(available) |> to_equal(~w[Andrew Freja Ronaldo Hitalo Alicia])

      [first_pair, second_pair] =
        html |> HtmlQuery.all(test_role: "track-of-work") |> Enum.map(&HtmlQuery.text/1)

      expect(first_pair) |> to_equal("")
      expect(second_pair) |> to_equal("")
    end

    test "are persistent once set", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      hobbit_babysitters = people_in_track(html, "1. Taking the hobbits to Eisengard")
      potato_boilers = people_in_track(html, "2. Boiling potatoes")

      expect(hobbit_babysitters) |> to_equal(~w[Andrew Freja])
      expect(potato_boilers) |> to_equal(~w[Ronaldo Hitalo])
    end
  end

  describe "when people aren't available to pair" do
    test "they don't get randomly assigned", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to unavailable
      html = send_person(view, at_index: 4, from: "available", to: "unavailable")
      unavailable = select_unavailable(html)

      expect(unavailable) |> to_equal(["Alicia"])
      refute "Alicia" in select_unpaired(html)

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      unavailable = select_unavailable(html)

      expect(unavailable) |> to_equal(["Alicia"])
      refute "Alicia" in select_unpaired(html)

      [first_pair, second_pair] =
        html
        |> HtmlQuery.all(test_role: "track-of-work")
        |> Enum.map(&HtmlQuery.text/1)
        |> Enum.map(&to_pairs/1)

      refute "Alicia" in first_pair
      refute "Alicia" in second_pair
    end

    test "they stay unavailable until moved", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send alicia from unpaired to unavailable
      send_person(view, at_index: 4, from: "available", to: "unavailable")
      {:ok, view, html} = live(conn, ~p"/projects/#{project.id}/pairing")
      unavailable = select_unavailable(html)

      expect(unavailable) |> to_contain("Alicia")

      # send alicia from unavailable to unpaired
      send_person(view, at_index: 0, from: "unavailable", to: "available")
      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")
      unpaired = select_unpaired(html)

      refute "Alicia" in select_unavailable(html)
      expect(unpaired) |> to_contain("Alicia")
    end

    test "people do not get assigned twice when randomized", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Andrew from unpaired to unavailable
      html = send_person(view, at_index: 0, from: "available", to: "unavailable")
      unavailable = select_unavailable(html)

      expect(unavailable) |> to_equal(["Andrew"])
      refute "Andrew" in select_unpaired(html)

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      unavailable = select_unavailable(html)
      expect(unavailable) |> to_equal(["Andrew"])

      [first_pair, second_pair] =
        html
        |> HtmlQuery.all(test_role: "track-of-work")
        |> Enum.map(&HtmlQuery.text/1)
        |> Enum.map(&to_pairs/1)

      refute "Andrew" in first_pair
      refute "Andrew" in second_pair
    end

    test "they don't get reset", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to unavailable
      send_person(view, at_index: 4, from: "available", to: "unavailable")

      {unavailable, unpaired} =
        view
        |> element("button", "Reset pairs")
        |> render_click()
        |> (fn html -> {select_unavailable(html), select_unpaired(html)} end).()

      expect(unavailable) |> to_equal(["Alicia"])
      refute "Alicia" in unpaired
    end

    test "the indices of people in the lists are recalculated", %{conn: conn, project: project} do
      # if we don't recalculate indices, we'll get the incorrect index on the front-end the second time you move someone in a list
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to unavailable
      send_person(view, at_index: 4, from: "available", to: "unavailable")

      html =
        view
        |> element("button", "Reset pairs")
        |> render_click()

      unavailable_indices =
        html
        |> HtmlQuery.find!(test_role: "unavailable")
        |> HtmlQuery.all("div[test-index]")
        |> Enum.map(&HtmlQuery.attr(&1, "test-index"))
        |> Enum.map(&String.to_integer/1)

      expect(unavailable_indices) |> to_equal([0])

      available_indices =
        html
        |> HtmlQuery.find!(test_role: "unpaired")
        |> HtmlQuery.all("div[test-index]")
        |> Enum.map(&HtmlQuery.attr(&1, "test-index"))
        |> Enum.map(&String.to_integer/1)

      expect(available_indices) |> to_equal([0, 1, 2, 3])
    end

    test "they can be moved back to 'unpaired' so they can be paired up again", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      send_person(view, at_index: 4, from: "available", to: "unavailable")

      {unavailable, unpaired} =
        view
        |> send_person(at_index: 0, from: "unavailable", to: "available")
        |> (fn html -> {select_unavailable(html), select_unpaired(html)} end).()

      expect(unavailable) |> to_be_empty()
      expect(unpaired) |> to_contain("Alicia")
    end

    test "they can be moved from a track to 'unavailable'", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      send_person(view, at_index: 4, from: "available", to: "2. Boiling potatoes")

      {unavailable, potato_boilers} =
        view
        |> send_person(at_index: 0, from: "2. Boiling potatoes", to: "unavailable")
        |> (fn html -> {select_unavailable(html), people_in_track(html, "2. Boiling potatoes")} end).()

      expect(unavailable) |> to_contain("Alicia")
      refute "Alicia" in potato_boilers
    end
  end

  describe "moving people" do
    test "... between tracks of work", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to first track
      html = send_person(view, at_index: 4, from: "available", to: "1. Taking the hobbits to Eisengard")
      hobbit_babysitters = people_in_track(html, "1. Taking the hobbits to Eisengard")

      expect(hobbit_babysitters) |> to_contain("Alicia")

      # send Alicia from first track to second track
      html = send_person(view, at_index: 0, from: "1. Taking the hobbits to Eisengard", to: "2. Boiling potatoes")
      hobbit_babysitters = people_in_track(html, "1. Taking the hobbits to Eisengard")
      potato_boilers = people_in_track(html, "2. Boiling potatoes")

      expect(hobbit_babysitters) |> to_be_empty()
      expect(potato_boilers) |> to_contain("Alicia")
    end

    test "to the same track of work is a no-op", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      send_person(view, at_index: 4, from: "available", to: "1. Taking the hobbits to Eisengard")

      hobbit_babysitters =
        view
        |> send_person(
          at_index: 0,
          from: "1. Taking the hobbits to Eisengard",
          to: "1. Taking the hobbits to Eisengard"
        )
        |> people_in_track("1. Taking the hobbits to Eisengard")

      expect(hobbit_babysitters) |> to_contain("Alicia")
    end

    test "from unpaired to unpaired is also a no-op", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      unpaired_people =
        view
        |> send_person(at_index: 0, from: "available", to: "available")
        |> select_unpaired()

      expect(unpaired_people) |> to_equal(~w[Andrew Freja Ronaldo Hitalo Alicia])
    end

    test "back to the 'unpaired' list", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to first track
      send_person(view, at_index: 4, from: "available", to: "1. Taking the hobbits to Eisengard")
      html = send_person(view, at_index: 0, from: "1. Taking the hobbits to Eisengard", to: "available")
      unpaired = select_unpaired(html)

      expect(unpaired) |> to_contain("Alicia")
      refute "Alicia" in people_in_track(html, "1. Taking the hobbits to Eisengard")

      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")
      unpaired = select_unpaired(html)

      expect(unpaired) |> to_contain("Alicia")
      refute "Alicia" in people_in_track(html, "1. Taking the hobbits to Eisengard")
    end
  end

  describe "the tracks of work" do
    test "are rendered as separate lists", %{conn: conn, project: project} do
      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      tracks =
        html
        |> HtmlQuery.all(test_role: "track-of-work")
        |> Enum.map(fn elem -> HtmlQuery.find!(elem, test_role: "track-name") end)
        |> Enum.map(fn elem -> HtmlQuery.attr(elem, "value") end)

      expect(tracks) |> to_contain("1. Taking the hobbits to Eisengard")
      expect(tracks) |> to_contain("2. Boiling potatoes")
    end

    test "can be edited", %{conn: conn, project: project} do
      {:ok, view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      html = rename_nth_track(view, html, 0, "Staring at the One Ring")

      track_title =
        html
        |> HtmlQuery.all("[test-role=track-of-work] input")
        |> Enum.at(0)
        |> HtmlQuery.attr("value")

      expect(track_title) |> to_equal("Staring at the One Ring")
    end

    test "can be deleted with allocation", %{conn: conn, project: project} do
      track = track_fixture(title: "2. Boiling potatoes", project_id: project.id)
      person = person_fixture(project_id: project.id, name: "New Person")

      OneTruePairing.Projects.allocate_person_to_track!(track.id, person.id)

      {:ok, view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      no_of_tracks =
        html |> HtmlQuery.all("[test-role=track-of-work]") |> Enum.count()

      tracks =
        view
        |> element("#delete-#{track.id}")
        |> render_click(%{"id" => track.id})
        |> HtmlQuery.all("[test-role=track-of-work]")

      expect(tracks) |> to_have_length(no_of_tracks - 1)
    end

    test "deleting track preserves allocations of previous days", %{conn: conn, project: project} do
      track = track_fixture(title: "2. Boiling potatoes", project_id: project.id)
      person = person_fixture(project_id: project.id, name: "New Person")

      {:ok, now} = DateTime.now("Etc/UTC")
      yesterday = DateTime.add(now, -1, :day)

      previous_allocation =
        allocation_fixture(track_id: track.id, person_id: person.id, inserted_at: yesterday, updated_at: yesterday)

      _current_allocation =
        allocation_fixture(track_id: track.id, person_id: person.id, inserted_at: now, updated_at: now)

      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      view
      |> element("#delete-#{track.id}")
      |> render_click(%{"id" => track.id})

      all_allocations = OneTruePairing.Projects.Allocation |> OneTruePairing.Repo.all()

      expect(all_allocations) |> to_contain(previous_allocation)
    end

    test "can be added", %{conn: conn, project: project} do
      {:ok, view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      no_of_tracks =
        html |> HtmlQuery.all("[test-role=track-of-work]") |> Enum.count()

      tracks =
        view
        |> element("button", "Add Track")
        |> render_click()
        |> HtmlQuery.all("[test-role=track-of-work]")

      expect(tracks) |> to_have_length(no_of_tracks + 1)
    end

    test "can have the same name", %{conn: conn, project: project} do
      {:ok, view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      html = rename_nth_track(view, html, 0, "2. Boiling potatoes")

      tracks =
        html
        |> HtmlQuery.all(test_role: "track-of-work")
        |> Enum.map(fn elem -> HtmlQuery.find!(elem, test_role: "track-name") end)
        |> Enum.map(fn elem -> HtmlQuery.attr(elem, "value") end)

      expect(tracks) |> to_equal(["2. Boiling potatoes", "2. Boiling potatoes"])
    end

    test "can be named 'unavailable'", %{conn: conn, project: project} do
      {:ok, view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      rename_nth_track(view, html, 0, "unavailable")

      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      tracks =
        html
        |> HtmlQuery.all(test_role: "track-of-work")
        |> Enum.map(fn elem -> HtmlQuery.find!(elem, test_role: "track-name") end)
        |> Enum.map(fn elem -> HtmlQuery.attr(elem, "value") end)

      expect(tracks) |> to_contain("unavailable")
      expect(tracks) |> to_contain("2. Boiling potatoes")
    end
  end

  describe "persistent allocations" do
    test "are sticky across page loads for the same day", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      hobbit_babysitters = people_in_track(html, "1. Taking the hobbits to Eisengard")
      potato_boilers = people_in_track(html, "2. Boiling potatoes")

      expect(hobbit_babysitters) |> to_equal(~w[Andrew Freja])
      expect(potato_boilers) |> to_equal(~w[Ronaldo Hitalo])

      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")
      hobbit_babysitters = people_in_track(html, "1. Taking the hobbits to Eisengard")
      potato_boilers = people_in_track(html, "2. Boiling potatoes")

      expect(hobbit_babysitters) |> to_equal(~w[Andrew Freja])
      expect(potato_boilers) |> to_equal(~w[Ronaldo Hitalo])
    end

    test "are deleted when the board is reset", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      view
      |> element("button", "Randomize pairs")
      |> render_click()

      view
      |> element("button", "Reset pairs")
      |> render_click()

      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      unpaired = select_unpaired(html)
      hobbit_babysitters = people_in_track(html, "1. Taking the hobbits to Eisengard")
      potato_boilers = people_in_track(html, "2. Boiling potatoes")

      expect(unpaired) |> to_contain("Andrew")
      expect(unpaired) |> to_contain("Freja")
      expect(unpaired) |> to_contain("Ronaldo")
      expect(unpaired) |> to_contain("Hitalo")
      expect(unpaired) |> to_contain("Alicia")

      expect(hobbit_babysitters) |> to_be_empty()
      expect(potato_boilers) |> to_be_empty()
    end

    test "are updated when someone is moved between tracks", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to first track
      html = send_person(view, at_index: 4, from: "available", to: "1. Taking the hobbits to Eisengard")
      hobbit_babysitters = people_in_track(html, "1. Taking the hobbits to Eisengard")

      expect(hobbit_babysitters) |> to_contain("Alicia")

      # send Alicia from first track to second track
      html = send_person(view, at_index: 0, from: "1. Taking the hobbits to Eisengard", to: "2. Boiling potatoes")
      hobbit_babysitters = people_in_track(html, "1. Taking the hobbits to Eisengard")
      potato_boilers = people_in_track(html, "2. Boiling potatoes")

      expect(hobbit_babysitters) |> to_be_empty()
      expect(potato_boilers) |> to_contain("Alicia")

      # reload the page
      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")
      hobbit_babysitters = people_in_track(html, "1. Taking the hobbits to Eisengard")
      potato_boilers = people_in_track(html, "2. Boiling potatoes")

      expect(hobbit_babysitters) |> to_be_empty()
      expect(potato_boilers) |> to_contain("Alicia")

      unpaired = select_unpaired(html)
      refute("Alicia" in unpaired)
    end
  end

  defp send_person(view, at_index: index, from: old_list, to: new_list) do
    view
    |> render_hook(:repositioned, %{
      "old" => index,
      "from" => %{"list_name" => old_list},
      "to" => %{"list_name" => new_list}
    })
  end

  defp rename_nth_track(view, html, position, new_name) do
    track_id =
      html
      |> HtmlQuery.all("[test-role=track-of-work] input")
      |> Enum.at(position)
      |> HtmlQuery.attr("name")

    view
    |> render_change(:save, %{track_id => new_name})
  end

  defp select_unpaired(html) do
    html
    |> HtmlQuery.find!(test_role: "unpaired")
    |> HtmlQuery.find!(test_role: "list")
    |> HtmlQuery.text()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim(&1))
    |> Enum.reject(fn str -> String.length(str) == 0 end)
  end

  def select_unavailable(html) do
    html
    |> HtmlQuery.find!(test_role: "unavailable")
    |> HtmlQuery.find!(test_role: "list")
    |> HtmlQuery.text()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim(&1))
    |> Enum.reject(fn str -> String.length(str) == 0 end)
  end

  defp people_in_track(html, track_name) do
    html
    |> HtmlQuery.find!(test_track_name: track_name)
    |> HtmlQuery.find!(test_role: "list")
    |> HtmlQuery.text()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim(&1))
    |> Enum.reject(fn str -> String.length(str) == 0 end)
  end

  defp to_pairs(track_of_work_innertext) do
    track_of_work_innertext
    |> String.split(~r[\s+])
    |> Enum.reject(&(String.length(&1) == 0))
  end
end
