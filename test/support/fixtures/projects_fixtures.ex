defmodule Mocks.HandRolled do
  defmacro new(stubbed_response) do
    quote do
      {:module, impl, _bytes, _method} =
        defmodule Impl do
          def load_project("1") do
            unquote(stubbed_response)
          end
        end

      impl
    end
  end
end

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
        name: "some name",
        project_id: project_fixture().id,
        unavailable: false,
        has_left_project: false
      })
      |> OneTruePairing.Projects.create_person()

    person
  end

  @doc """
  Generate a track of work.
  """
  def track_fixture(attrs \\ %{}) do
    {:ok, track} =
      attrs
      |> Enum.into(%{
        title: "underwater basket weaving",
        project_id: project_fixture().id
      })
      |> OneTruePairing.Projects.create_track()

    track
  end
end
