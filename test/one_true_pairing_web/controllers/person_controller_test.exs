defmodule OneTruePairingWeb.PersonControllerTest do
  use OneTruePairingWeb.ConnCase, async: true

  alias OneTruePairing.Projects

  import Expect
  import Expect.Matchers
  import OneTruePairing.ProjectsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup do
    [project: OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Project{name: "Fellowship"})]
  end

  describe "index" do
    test "lists all persons", %{conn: conn, project: project} do
      response = get(conn, ~p"/projects/#{project.id}/persons") |> html_response(200)
      expect(response) |> to_match_regex(~r"Listing Persons")
    end
  end

  describe "new person" do
    test "renders form", %{conn: conn, project: project} do
      response = get(conn, ~p"/projects/#{project.id}/persons/new") |> html_response(200)
      expect(response) |> to_match_regex(~r"New Person")
    end
  end

  describe "create person" do
    test "redirects to show when data is valid", %{conn: conn, project: project} do
      conn = post(conn, ~p"/projects/#{project.id}/persons", person: @create_attrs)

      %{id: id} = redirected_params(conn)
      url = redirected_to(conn)
      expect(url) |> to_equal(~p"/projects/#{project.id}/persons/#{id}")

      response = get(conn, ~p"/projects/#{project.id}/persons/#{id}") |> html_response(200)
      expect(response) |> to_match_regex(~r"Person #{id}")
    end

    test "renders errors when data is invalid", %{conn: conn, project: project} do
      response = post(conn, ~p"/projects/#{project.id}/persons", person: @invalid_attrs) |> html_response(200)
      expect(response) |> to_match_regex(~r"New Person")
    end
  end

  describe "edit person" do
    setup [:create_person]

    test "renders form for editing chosen person", %{conn: conn, person: person, project: project} do
      response = get(conn, ~p"/projects/#{project.id}/persons/#{person}/edit") |> html_response(200)
      expect(response) |> to_match_regex(~r"Edit Person")
    end
  end

  describe "update person" do
    setup [:create_person]

    test "redirects when data is valid", %{conn: conn, person: person, project: project} do
      conn = put(conn, ~p"/projects/#{project.id}/persons/#{person}", person: @update_attrs)
      url = redirected_to(conn)
      expect(url) |> to_equal(~p"/projects/#{project.id}/persons/#{person}")

      response = get(conn, ~p"/projects/#{project.id}/persons/#{person}") |> html_response(200)
      expect(response) |> to_match_regex(~r"some updated name")
    end

    test "edits the attributes of the person", %{conn: conn, person: person, project: project} do
      attrs = %{name: "Charlie Murphy", unavailable: true, has_left_project: true}
      put(conn, ~p"/projects/#{project.id}/persons/#{person}", person: attrs)

      [person] = Projects.list_people()

      expect(person.name) |> to_equal("Charlie Murphy")
      expect(person.unavailable) |> to_equal(true)
      expect(person.has_left_project) |> to_equal(true)
    end

    test "renders errors when data is invalid", %{conn: conn, person: person, project: project} do
      response = put(conn, ~p"/projects/#{project.id}/persons/#{person}", person: @invalid_attrs) |> html_response(200)
      expect(response) |> to_match_regex(~r"Edit Person")
    end
  end

  describe "delete person" do
    setup [:create_person]

    test "deletes chosen person", %{conn: conn, person: person, project: project} do
      conn = delete(conn, ~p"/projects/#{project.id}/persons/#{person}")
      url = redirected_to(conn)
      expect(url) |> to_equal(~p"/projects/#{project.id}/persons")

      assert_error_sent 404, fn ->
        get(conn, ~p"/projects/#{project.id}/persons/#{person}")
      end
    end
  end

  defp create_person(_) do
    person = person_fixture()
    %{person: person}
  end
end
