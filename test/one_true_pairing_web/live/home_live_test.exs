defmodule OneTruePairingWeb.HomeLiveTest do
  # @related [impl](lib/one_true_pairing_web/live/home_live.ex)
  use OneTruePairingWeb.ConnCase, async: true

  import Expect
  import Expect.Matchers
  import Phoenix.LiveViewTest
  import OneTruePairing.ProjectsFixtures

  describe "the homepage" do
    test "shows a list of previously created projects", %{conn: conn} do
      project_fixture(name: "Fellowship")
      project_fixture(name: "Mordor Cleanup Crew")

      {:ok, _view, html} = live(conn, ~p"/")

      expect(html, to: match_regex(~r/Fellowship/))
      expect(html, to: match_regex(~r/Mordor Cleanup Crew/))
    end

    test "includes a link to each project's pairing page", %{conn: conn} do
      project = project_fixture(name: "Fellowship")

      {:ok, _view, html} = live(conn, ~p"/")

      expect(html, to: match_regex(~r"/projects/#{project.id}/pairing"))
    end

    test "includes a link to create a new project", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      expect(html, to: match_regex(~r"/projects/new"))
    end
  end
end
