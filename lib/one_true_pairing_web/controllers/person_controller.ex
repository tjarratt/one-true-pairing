defmodule OneTruePairingWeb.PersonController do
  use OneTruePairingWeb, :controller

  alias OneTruePairing.Projects
  alias OneTruePairing.Projects.Person

  def index(conn, %{"project_id" => project_id}) do
    persons = Projects.persons_for(project_id: project_id)
    render(conn, :index, persons: persons, project: project_id)
  end

  def new(conn, %{"project_id" => project_id}) do
    changeset = Projects.change_person(%Person{})
    render(conn, :new, changeset: changeset, project: project_id)
  end

  def create(conn, %{"person" => person_params, "project_id" => project_id}) do
    full_params = Map.merge(person_params, %{"project_id" => project_id})

    case Projects.create_person(full_params) do
      {:ok, person} ->
        conn
        |> put_flash(:info, "Person created successfully.")
        |> redirect(to: ~p"/projects/#{project_id}/persons/#{person}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, project: project_id)
    end
  end

  def show(conn, %{"id" => id, "project_id" => project_id}) do
    person = Projects.get_person!(id)
    render(conn, :show, person: person, project: project_id)
  end

  def edit(conn, %{"id" => id, "project_id" => project_id}) do
    person = Projects.get_person!(id)
    changeset = Projects.change_person(person)
    render(conn, :edit, person: person, changeset: changeset, project: project_id)
  end

  def update(conn, %{"id" => id, "person" => person_params, "project_id" => project_id}) do
    person = Projects.get_person!(id)

    case Projects.update_person(person, person_params) do
      {:ok, person} ->
        conn
        |> put_flash(:info, "Person updated successfully.")
        |> redirect(to: ~p"/projects/#{project_id}/persons/#{person}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, person: person, changeset: changeset, project: project_id)
    end
  end

  def delete(conn, %{"id" => id, "project_id" => project_id}) do
    person = Projects.get_person!(id)
    {:ok, _person} = Projects.delete_person(person)

    conn
    |> put_flash(:info, "Person deleted successfully.")
    |> redirect(to: ~p"/projects/#{project_id}/persons")
  end
end
