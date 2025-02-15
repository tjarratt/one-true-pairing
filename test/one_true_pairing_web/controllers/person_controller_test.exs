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
      conn = get(conn, ~p"/projects/#{project.id}/persons")
      assert html_response(conn, 200) =~ "Listing Persons"
    end
  end

  describe "new person" do
    test "renders form", %{conn: conn, project: project} do
      conn = get(conn, ~p"/projects/#{project.id}/persons/new")
      assert html_response(conn, 200) =~ "New Person"
    end
  end

  describe "create person" do
    test "redirects to show when data is valid", %{conn: conn, project: project} do
      conn = post(conn, ~p"/projects/#{project.id}/persons", person: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/projects/#{project.id}/persons/#{id}"

      conn = get(conn, ~p"/projects/#{project.id}/persons/#{id}")
      assert html_response(conn, 200) =~ "Person #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn, project: project} do
      conn = post(conn, ~p"/projects/#{project.id}/persons", person: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Person"
    end
  end

  describe "edit person" do
    setup [:create_person]

    test "renders form for editing chosen person", %{conn: conn, person: person, project: project} do
      conn = get(conn, ~p"/projects/#{project.id}/persons/#{person}/edit")
      assert html_response(conn, 200) =~ "Edit Person"
    end
  end

  describe "update person" do
    setup [:create_person]

    test "redirects when data is valid", %{conn: conn, person: person, project: project} do
      conn = put(conn, ~p"/projects/#{project.id}/persons/#{person}", person: @update_attrs)
      assert redirected_to(conn) == ~p"/projects/#{project.id}/persons/#{person}"

      conn = get(conn, ~p"/projects/#{project.id}/persons/#{person}")
      assert html_response(conn, 200) =~ "some updated name"
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
      conn = put(conn, ~p"/projects/#{project.id}/persons/#{person}", person: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Person"
    end
  end

  describe "delete person" do
    setup [:create_person]

    test "deletes chosen person", %{conn: conn, person: person, project: project} do
      conn = delete(conn, ~p"/projects/#{project.id}/persons/#{person}")
      assert redirected_to(conn) == ~p"/projects/#{project.id}/persons"

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
