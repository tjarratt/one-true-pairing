defmodule OneTruePairingWeb.PairingLiveTest do
  # @related [impl](lib/one_true_pairing_web/live/pair_live.ex)
  use OneTruePairingWeb.ConnCase

  import Phoenix.LiveViewTest
  import OneTruePairing.ProjectsFixtures

  setup do
    project = project_fixture(name: "Fellowship")

    track_fixture(title: "Taking the hobbits to Eisengard", project_id: project.id)
    track_fixture(title: "Boiling potatoes", project_id: project.id)

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

    assert list == ~w[Andrew Freja Ronaldo Hitalo Alicia]
  end

  test "it has a title", %{conn: conn, project: project} do
    {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

    header = html |> HtmlQuery.find("h1") |> HtmlQuery.text()

    assert header =~ "Let's pair today"
  end

  test "it renders the list of people available to pair", %{conn: conn, project: project} do
    {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

    list = html |> HtmlQuery.find!("#pairing_list") |> HtmlQuery.text()

    assert list =~ "Andrew"
    assert list =~ "Freja"
    assert list =~ "Ronaldo"
    assert list =~ "Hitalo"
    assert list =~ "Alicia"
  end

  describe "randomising pairs" do
    test "puts two people in each track of work, and the rest remain unpaired", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      [first_pair, second_pair] =
        html |> HtmlQuery.all(test_role: "track-of-work") |> Enum.map(&HtmlQuery.text/1)

      assert first_pair =~ "Andrew"
      assert first_pair =~ "Freja"

      assert second_pair =~ "Ronaldo"
      assert second_pair =~ "Hitalo"

      unpaired_folks = select_unpaired(html)
      assert unpaired_folks == ["Alicia"]
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

      assert ~w[Andrew Freja] == people_in_track(html, "Taking the hobbits to Eisengard")
      assert ~w[Ronaldo Hitalo] == people_in_track(html, "Boiling potatoes")
    end

    test "does not change the tracks of work", %{conn: conn, project: project} do
      {:ok, view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      rename_first_track(view, html, "Staring at the One Ring")

      track_titles =
        view
        |> element("button", "Randomize pairs")
        |> render_click()
        |> HtmlQuery.all("[test-role=track-of-work] input")
        |> Enum.map(&HtmlQuery.attr(&1, "value"))

      assert "Staring at the One Ring" in track_titles
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

      available = html |> HtmlQuery.find!("#pairing_list") |> HtmlQuery.text()

      assert available =~ "Andrew"
      assert available =~ "Freja"
      assert available =~ "Ronaldo"
      assert available =~ "Hitalo"
      assert available =~ "Alicia"

      [first_pair, second_pair] =
        html |> HtmlQuery.all(test_role: "track-of-work") |> Enum.map(&HtmlQuery.text/1)

      assert first_pair == ""
      assert second_pair == ""
    end

    test "are persistent once set", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      assert ~w[Andrew Freja] == people_in_track(html, "Taking the hobbits to Eisengard")
      assert ~w[Ronaldo Hitalo] == people_in_track(html, "Boiling potatoes")
    end
  end

  describe "when people aren't available to pair" do
    test "they don't get randomly assigned", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to unavailable
      html = send_person(view, at_index: 4, from: "available", to: "unavailable")

      assert ["Alicia"] == select_unavailable(html)

      refute "Alicia" in select_unpaired(html)

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      assert ["Alicia"] == select_unavailable(html)

      refute "Alicia" in select_unpaired(html)

      [first_pair, second_pair] =
        html |> HtmlQuery.all(test_role: "track-of-work") |> Enum.map(&HtmlQuery.text/1)

      refute first_pair =~ "Alicia"
      refute second_pair =~ "Alicia"
    end

    test "people do not get assigned twice when randomized", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Andrew from unpaired to unavailable
      html = send_person(view, at_index: 0, from: "available", to: "unavailable")

      assert ["Andrew"] == select_unavailable(html)
      refute "Andrew" in select_unpaired(html)

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      assert ["Andrew"] == select_unavailable(html)

      [first_pair, second_pair] =
        html |> HtmlQuery.all(test_role: "track-of-work") |> Enum.map(&HtmlQuery.text/1)

      refute first_pair =~ "Andrew"
      refute second_pair =~ "Andrew"
    end

    test "they don't get reset", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to unavailable
      send_person(view, at_index: 4, from: "available", to: "unavailable")

      html =
        view
        |> element("button", "Reset pairs")
        |> render_click()

      assert ["Alicia"] == select_unavailable(html)
      refute "Alicia" in select_unpaired(html)
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

      assert unavailable_indices == [0]

      available_indices =
        html
        |> HtmlQuery.find!(test_role: "unpaired")
        |> HtmlQuery.all("div[test-index]")
        |> Enum.map(&HtmlQuery.attr(&1, "test-index"))
        |> Enum.map(&String.to_integer/1)

      assert available_indices == [0, 1, 2, 3]
    end

    test "they can be moved back to 'unpaired' so they can be paired up again", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      send_person(view, at_index: 4, from: "available", to: "unavailable")
      html = send_person(view, at_index: 0, from: "unavailable", to: "available")

      assert [] == select_unavailable(html)
      assert "Alicia" in select_unpaired(html)
    end

    test "they can be moved from a track to 'unavailable'", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      send_person(view, at_index: 4, from: "available", to: "Boiling potatoes")
      html = send_person(view, at_index: 0, from: "Boiling potatoes", to: "unavailable")

      assert "Alicia" in select_unavailable(html)
      refute "Alicia" in people_in_track(html, "Boiling potatoes")
    end
  end

  describe "moving people" do
    test "... between tracks of work", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to first track
      html = send_person(view, at_index: 4, from: "available", to: "Taking the hobbits to Eisengard")
      assert "Alicia" in people_in_track(html, "Taking the hobbits to Eisengard")

      # send Alicia from first track to second track
      html = send_person(view, at_index: 0, from: "Taking the hobbits to Eisengard", to: "Boiling potatoes")
      assert [] == people_in_track(html, "Taking the hobbits to Eisengard")
      assert "Alicia" in people_in_track(html, "Boiling potatoes")
    end

    test "to the same track of work is a no-op", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      send_person(view, at_index: 4, from: "available", to: "Taking the hobbits to Eisengard")

      html =
        send_person(view, at_index: 0, from: "Taking the hobbits to Eisengard", to: "Taking the hobbits to Eisengard")

      assert ["Alicia"] == people_in_track(html, "Taking the hobbits to Eisengard")
    end

    test "from unpaired to unpaired is also a no-op", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      unpaired_people =
        view
        |> send_person(at_index: 0, from: "available", to: "available")
        |> select_unpaired()

      assert ~w[Andrew Freja Ronaldo Hitalo Alicia] = unpaired_people
    end

    test "back to the 'unpaired' list", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to first track
      send_person(view, at_index: 4, from: "available", to: "Taking the hobbits to Eisengard")
      html = send_person(view, at_index: 0, from: "Taking the hobbits to Eisengard", to: "available")

      assert "Alicia" in select_unpaired(html)
      refute "Alicia" in people_in_track(html, "Taking the hobbits to Eisengard")

      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      assert "Alicia" in select_unpaired(html)
      refute "Alicia" in people_in_track(html, "Taking the hobbits to Eisengard")
    end
  end

  describe "the tracks of work" do
    test "are rendered as separate lists", %{conn: conn, project: project} do
      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      list =
        html
        |> HtmlQuery.all(test_role: "track-of-work")
        |> Enum.map(fn elem -> HtmlQuery.find!(elem, test_role: "track-name") end)
        |> Enum.map(fn elem -> HtmlQuery.attr(elem, "value") end)

      assert Enum.member?(list, "Taking the hobbits to Eisengard")
      assert Enum.member?(list, "Boiling potatoes")
    end

    test "can be edited", %{conn: conn, project: project} do
      {:ok, view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      html = rename_first_track(view, html, "Staring at the One Ring")

      track_title =
        html
        |> HtmlQuery.all("[test-role=track-of-work] input")
        |> Enum.at(0)
        |> HtmlQuery.attr("value")

      assert track_title == "Staring at the One Ring"
    end
  end

  describe "persistent allocations" do
    test "are sticky across page loads for the same day", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      assert ~w[Andrew Freja] == people_in_track(html, "Taking the hobbits to Eisengard")
      assert ~w[Ronaldo Hitalo] == people_in_track(html, "Boiling potatoes")

      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

      assert ~w[Andrew Freja] == people_in_track(html, "Taking the hobbits to Eisengard")
      assert ~w[Ronaldo Hitalo] == people_in_track(html, "Boiling potatoes")
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

      assert "Andrew" in unpaired
      assert "Freja" in unpaired
      assert "Ronaldo" in unpaired
      assert "Hitalo" in unpaired
      assert "Alicia" in unpaired

      assert [] == people_in_track(html, "Taking the hobbits to Eisengard")
      assert [] == people_in_track(html, "Boiling potatoes")
    end

    test "are updated when someone is moved between tracks", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to first track
      html = send_person(view, at_index: 4, from: "available", to: "Taking the hobbits to Eisengard")
      assert "Alicia" in people_in_track(html, "Taking the hobbits to Eisengard")

      # send Alicia from first track to second track
      html = send_person(view, at_index: 0, from: "Taking the hobbits to Eisengard", to: "Boiling potatoes")
      assert [] == people_in_track(html, "Taking the hobbits to Eisengard")
      assert "Alicia" in people_in_track(html, "Boiling potatoes")

      # reload the page
      {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")
      assert [] == people_in_track(html, "Taking the hobbits to Eisengard")
      assert "Alicia" in people_in_track(html, "Boiling potatoes")

      unpaired = select_unpaired(html)
      assert "Alicia" not in unpaired
    end
  end

  defp send_person(view, at_index: index, from: old_list, to: new_list) do
    view
    |> render_hook(:repositioned, %{
      "old" => index,
      "from" => %{"list_id" => old_list},
      "to" => %{"list_id" => new_list}
    })
  end

  defp rename_first_track(view, html, new_name) do
    track_id =
      html
      |> HtmlQuery.all("[test-role=track-of-work] input")
      |> Enum.at(0)
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
end
