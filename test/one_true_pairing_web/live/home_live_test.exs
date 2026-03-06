defmodule OneTruePairingWeb.HomeLiveTest do
  # @related [impl](lib/one_true_pairing_web/live/home_live.ex)
  use OneTruePairingWeb.ConnCase, async: true

  import Expect
  import Expect.Matchers
  import Phoenix.LiveViewTest, only: [element: 3, live: 2, render: 1]

  import OneTruePairing.ProjectsFixtures,
    only: [
      person_fixture: 0,
      person_fixture: 1,
      project_fixture: 0,
      project_fixture: 1,
      track_fixture: 0,
      track_fixture: 1
    ]

  describe "the homepage" do
    test "shows a list of previously created projects", %{conn: conn} do
      project_fixture(name: "Fellowship")
      project_fixture(name: "Mordor Cleanup Crew")

      {:ok, _view, html} = live(conn, ~p"/")

      projects = html |> HtmlQuery.table(headers: false) |> List.flatten()

      expect(projects, to: contain("Fellowship"))
      expect(projects, to: contain("Mordor Cleanup Crew"))
    end

    test "includes a link to each project's pairing page", %{conn: conn} do
      project = project_fixture(name: "Fellowship")

      {:ok, view, _html} = live(conn, ~p"/")

      phx_onclick = view |> element("td", "Fellowship") |> render() |> HtmlQuery.attr("phx-click")

      expect(phx_onclick, to: match_regex(~r"/projects/#{project.id}/pairing"))
    end

    test "includes a link to create a new project", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      hyperlink = view |> element("a", "New Project") |> render() |> HtmlQuery.attr("href")

      expect(hyperlink, to: equal("/projects/new"))
    end
  end
end
