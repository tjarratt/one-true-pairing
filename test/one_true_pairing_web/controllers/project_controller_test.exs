defmodule OneTruePairingWeb.ProjectControllerTest do
  use OneTruePairingWeb.ConnCase

  import OneTruePairing.ProjectsFixtures

  @create_attrs %{name: "Cool project"}
  @update_attrs %{name: "Cooler project name ;)"}
  @invalid_attrs %{name: nil}

  describe "listing all projects" do
    test "has a header", %{conn: conn} do
      conn = get(conn, ~p"/projects")

      assert html_response(conn, 200) =~ "All Projects"
    end

    test "shows previously created projects", %{conn: conn} do
      project_fixture(name: "Project A")
      project_fixture(name: "Project B")

      conn = get(conn, ~p"/projects")
      html = html_response(conn, 200)

      assert html =~ "Project A"
      assert html =~ "Project B"
    end

    test "has links to manage a project", %{conn: conn} do
      project = project_fixture(name: "Project A")

      conn = get(conn, ~p"/projects")
      html = html_response(conn, 200) |> HtmlQuery.parse()

      links =
        html
        |> HtmlQuery.all("a")
        |> Enum.map(&HtmlQuery.attr(&1, "href"))

      assert "/projects/#{project.id}" in links
      assert "/projects/#{project.id}/edit" in links
    end

    test "can navigate to create a new project", %{conn: conn} do
      link =
        get(conn, ~p"/projects")
        |> html_response(200)
        |> HtmlQuery.parse()
        |> HtmlQuery.find!("a[href='/projects/new']")

      assert "New Project" == HtmlQuery.text(link)
    end
  end

  describe "creating a project" do
    test "the new page has a form", %{conn: conn} do
      conn = get(conn, ~p"/projects/new")
      response = html_response(conn, 200)
      html = response |> HtmlQuery.parse()

      header = html |> HtmlQuery.find!("h1") |> HtmlQuery.text()
      assert header == "New Project"

      {input, _attrs, _children} = html |> HtmlQuery.find!("#project_name")
      assert input == "input"

      assert response =~ "Save Project"
      assert response =~ "Back to projects"
    end

    test "creating redirects to show when the data is valid", %{conn: conn} do
      conn = post(conn, ~p"/projects", project: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/projects/#{id}"

      conn = get(conn, ~p"/projects/#{id}")
      assert html_response(conn, 200) =~ "Project #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/projects", project: @invalid_attrs)
      html = html_response(conn, 200)

      assert html =~ "New Project"
      assert html =~ "Oops"
    end
  end

  describe "editing a project" do
    test "displays the project as a form", %{conn: conn} do
      project = project_fixture(name: "Edit me")
      conn = get(conn, ~p"/projects/#{project}/edit")
      response = html_response(conn, 200)

      assert response =~ "Edit Project #{project.id}"

      input = response |> HtmlQuery.parse() |> HtmlQuery.find!("#project_name")

      assert HtmlQuery.attr(input, "value") == "Edit me"
    end

    test "has a back button", %{conn: conn} do
      project = project_fixture(name: "Edit me")
      conn = get(conn, ~p"/projects/#{project}/edit")
      response = html_response(conn, 200)

      assert response =~ "Back to projects"
    end

    test "redirects when data is valid", %{conn: conn} do
      project = project_fixture(name: "Cool name")

      conn = put(conn, ~p"/projects/#{project}", project: @update_attrs)
      assert redirected_to(conn) == ~p"/projects/#{project}"

      conn = get(conn, ~p"/projects/#{project}")
      assert html_response(conn, 200) =~ "Cooler project name ;)"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      project = project_fixture()
      conn = put(conn, ~p"/projects/#{project}", project: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Project"
    end
  end

  describe "viewing a single project" do
    test "has a link to edit", %{conn: conn} do
      project = project_fixture()
      conn = get(conn, ~p"/projects/#{project}")
      response = html_response(conn, 200)

      assert response =~ "/projects/#{project.id}/edit"
    end

    test "has a link to navigate back", %{conn: conn} do
      project = project_fixture()
      conn = get(conn, ~p"/projects/#{project}")
      response = html_response(conn, 200)

      assert response =~ "Back to projects"
    end
  end
end
