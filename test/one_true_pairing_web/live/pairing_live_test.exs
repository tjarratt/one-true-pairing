defmodule OneTruePairingWeb.PairingLiveTest do
  use OneTruePairingWeb.ConnCase

  import Phoenix.LiveViewTest

  setup do
    project = OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Project{name: "Fellowship"})
    create_person(project, "Andrew")
    create_person(project, "Freja")
    create_person(project, "Ronaldo")
    create_person(project, "Hitalo")
    create_person(project, "Alicia")

    [project: project]
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

  test "it renders the tracks of work", %{conn: conn, project: project} do
    {:ok, _view, html} = live(conn, ~p"/projects/#{project.id}/pairing")

    list =
      html
      |> HtmlQuery.all(test_role: "track-of-work")
      |> Enum.map(fn elem -> HtmlQuery.find!(elem, test_role: "track-name") end)
      |> Enum.map(fn elem -> HtmlQuery.attr(elem, "value") end)

    assert Enum.member?(list, "Ocean")
    assert Enum.member?(list, "Not Ocean")
  end

  test "randomising pairs", %{conn: conn, project: project} do
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

    unpaired_folks = html |> HtmlQuery.find!(test_role: "unpaired") |> HtmlQuery.text()

    assert unpaired_folks == "Alicia"
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

    [first_pair, second_pair] =
      html |> HtmlQuery.all(test_role: "track-of-work") |> Enum.map(&HtmlQuery.text/1)

    assert first_pair =~ "Andrew"
    assert first_pair =~ "Freja"

    assert second_pair =~ "Ronaldo"
    assert second_pair =~ "Hitalo"
  end

  test "resetting pairs", %{conn: conn, project: project} do
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

  describe "when people aren't available to pair" do
    test "they don't get randomly assigned", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to unavailable
      html =
        view
        |> render_hook(:repositioned, %{
          "id" => "4",
          "from" => %{"list_id" => "available"},
          "to" => %{"list_id" => "unavailable"}
        })

      unavailable = html |> HtmlQuery.find!(test_role: "unavailable") |> HtmlQuery.text()
      assert unavailable == "Alicia"

      available = html |> HtmlQuery.find(test_role: "unpaired") |> HtmlQuery.text()
      refute available =~ "Alicia"

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      unavailable = html |> HtmlQuery.find!(test_role: "unavailable") |> HtmlQuery.text()
      assert unavailable == "Alicia"

      [first_pair, second_pair] =
        html |> HtmlQuery.all(test_role: "track-of-work") |> Enum.map(&HtmlQuery.text/1)

      refute first_pair =~ "Alicia"
      refute second_pair =~ "Alicia"
    end

    test "people do not get assigned twice when randomized", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Andrew from unpaired to unavailable
      html =
        view
        |> render_hook(:repositioned, %{
          "id" => "0",
          "from" => %{"list_id" => "available"},
          "to" => %{"list_id" => "unavailable"}
        })

      unavailable = html |> HtmlQuery.find!(test_role: "unavailable") |> HtmlQuery.text()
      assert unavailable == "Andrew"

      available = html |> HtmlQuery.find(test_role: "unpaired") |> HtmlQuery.text()
      refute available =~ "Andrew"

      html =
        view
        |> element("button", "Randomize pairs")
        |> render_click()

      unavailable = html |> HtmlQuery.find!(test_role: "unavailable") |> HtmlQuery.text()
      assert unavailable == "Andrew"

      [first_pair, second_pair] =
        html |> HtmlQuery.all(test_role: "track-of-work") |> Enum.map(&HtmlQuery.text/1)

      refute first_pair =~ "Andrew"
      refute second_pair =~ "Andrew"
    end

    test "they don't get reset", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/projects/#{project.id}/pairing")

      # send Alicia from unpaired to unavailable
      view
      |> render_hook(:repositioned, %{
        "id" => "4",
        "from" => %{"list_id" => "available"},
        "to" => %{"list_id" => "unavailable"}
      })

      html =
        view
        |> element("button", "Reset pairs")
        |> render_click()

      unavailable = html |> HtmlQuery.find!(test_role: "unavailable") |> HtmlQuery.text()
      assert unavailable == "Alicia"

      available = html |> HtmlQuery.find!(test_role: "unpaired") |> HtmlQuery.text()
      refute available =~ "Alicia"
    end
  end

  def create_person(project, name) do
    OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{
      name: name,
      project_id: project.id
    })
  end
end
