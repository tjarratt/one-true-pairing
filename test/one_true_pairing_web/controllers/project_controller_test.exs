defmodule OneTruePairingWeb.ProjectControllerTest do
  use OneTruePairingWeb.ConnCase

  import OneTruePairing.ProjectsFixtures
  import Expect
  import Expect.Matchers

  @create_attrs %{name: "Cool project"}
  @update_attrs %{name: "Cooler project name ;)"}
  @invalid_attrs %{name: nil}

  describe "listing all projects" do
    test "has a header", %{conn: conn} do
      conn = get(conn, ~p"/projects")
      response = html_response(conn, 200)
      expect(response) |> to_match_regex(~r"All Projects")
    end

    test "shows previously created projects", %{conn: conn} do
      project_fixture(name: "Project A")
      project_fixture(name: "Project B")

      conn = get(conn, ~p"/projects")
      html = html_response(conn, 200)

      expect(html) |> to_match_regex(~r"Project A")
      expect(html) |> to_match_regex(~r"Project B")
    end

    test "has links to manage a project", %{conn: conn} do
      project = project_fixture(name: "Project A")

      conn = get(conn, ~p"/projects")
      html = html_response(conn, 200) |> HtmlQuery.parse()

      links =
        html
        |> HtmlQuery.all("a")
        |> Enum.map(&HtmlQuery.attr(&1, "href"))

      expect(links) |> to_contain("/projects/#{project.id}")
      expect(links) |> to_contain("/projects/#{project.id}/edit")
    end

    test "can navigate to create a new project", %{conn: conn} do
      link_text =
        get(conn, ~p"/projects")
        |> html_response(200)
        |> HtmlQuery.parse()
        |> HtmlQuery.find!("a[href='/projects/new']")
        |> HtmlQuery.text()

      expect(link_text) |> to_equal("New Project")
    end
  end

  describe "creating a project" do
    test "the new page has a form", %{conn: conn} do
      conn = get(conn, ~p"/projects/new")
      response = html_response(conn, 200)
      html = response |> HtmlQuery.parse()

      header = html |> HtmlQuery.find!("h1") |> HtmlQuery.text()
      expect(header) |> to_equal("New Project")

      {input, _attrs, _children} = html |> HtmlQuery.find!("#project_name")
      expect(input) |> to_equal("input")

      expect(response) |> to_match_regex(~r"Save Project")
      expect(response) |> to_match_regex(~r"Back to projects")
    end

    test "creating redirects to show when the data is valid", %{conn: conn} do
      conn = post(conn, ~p"/projects", project: @create_attrs)

      %{id: id} = redirected_params(conn)
      url = redirected_to(conn)
      expect(url) |> to_equal(~p"/projects/#{id}")

      response = get(conn, ~p"/projects/#{id}") |> html_response(200)
      expect(response) |> to_match_regex(~r"Project #{id}")
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/projects", project: @invalid_attrs)
      html = html_response(conn, 200)

      expect(html) |> to_match_regex(~r"New Project")
      expect(html) |> to_match_regex(~r"Oops")
    end
  end

  describe "editing a project" do
    test "displays the project as a form", %{conn: conn} do
      project = project_fixture(name: "Edit me")
      conn = get(conn, ~p"/projects/#{project}/edit")
      response = html_response(conn, 200)

      expect(response) |> to_match_regex(~r"Edit Project #{project.id}")

      input_value = response |> HtmlQuery.parse() |> HtmlQuery.find!("#project_name") |> HtmlQuery.attr("value")

      expect(input_value) |> to_equal("Edit me")
    end

    test "has a back button", %{conn: conn} do
      project = project_fixture(name: "Edit me")
      conn = get(conn, ~p"/projects/#{project}/edit")
      response = html_response(conn, 200)

      expect(response) |> to_match_regex(~r"Back to projects")
    end

    test "redirects when data is valid", %{conn: conn} do
      project = project_fixture(name: "Cool name")

      conn = put(conn, ~p"/projects/#{project}", project: @update_attrs)
      url = redirected_to(conn)
      expect(url) |> to_equal(~p"/projects/#{project}")

      response = get(conn, ~p"/projects/#{project}") |> html_response(200)
      expect(response) |> to_match_regex(~r"Cooler project name")
    end

    test "renders errors when data is invalid", %{conn: conn} do
      project = project_fixture()
      response = put(conn, ~p"/projects/#{project}", project: @invalid_attrs) |> html_response(200)

      expect(response) |> to_match_regex(~r"Edit Project")
    end
  end

  describe "viewing a single project" do
    test "has a link to edit", %{conn: conn} do
      project = project_fixture()
      conn = get(conn, ~p"/projects/#{project}")
      response = html_response(conn, 200)

      expect(response) |> to_match_regex(~r"/projects/#{project.id}/edit")
    end

    test "has a link to navigate back", %{conn: conn} do
      project = project_fixture()
      conn = get(conn, ~p"/projects/#{project}")
      response = html_response(conn, 200)

      expect(response) |> to_match_regex(~r"Back to projects")
    end
  end
end
