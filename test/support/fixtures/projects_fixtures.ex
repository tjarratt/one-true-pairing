defmodule OneTruePairing.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OneTruePairing.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> OneTruePairing.Projects.create_project()

    project
  end

  @doc """
  Generate a person.
  """
  def person_fixture(attrs \\ %{}) do
    {:ok, person} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> OneTruePairing.Projects.create_person()

    person
  end
end
