defmodule OneTruePairing.Projects do
  # @related [test](test/one_true_pairing/projects_test.exs)

  defmodule ProjectProvider do
    @type person_t() :: %{name: binary(), id: pos_integer()}
    @type track_t() :: %{name: binary(), id: pos_integer(), people: Enum.t(person_t())}

    @callback load_project(project_id: pos_integer()) :: %{unpaired: Enum.t(person_t()), tracks: Enum.t(track_t())}
  end

  @behaviour ProjectProvider

  import Ecto.Query, warn: false

  alias OneTruePairing.Repo
  alias OneTruePairing.Pairing
  alias OneTruePairing.Projects.Track
  alias OneTruePairing.Projects.Person
  alias OneTruePairing.Projects.Project
  alias OneTruePairing.Projects.Allocation

  # # # new interface

  @impl ProjectProvider
  def load_project(project_id) do
    people = persons_for(project_id: project_id) |> Enum.map(&%{name: &1.name, id: &1.id, unavailable: &1.unavailable})

    tracks =
      tracks_for(project_id: project_id)
      |> Enum.map(fn track ->
        allocated_ids = allocations_for_track(track.id) |> Enum.map(& &1.person_id)
        allocated_people = Enum.filter(people, fn p -> p.id in allocated_ids end)

        %{
          people: allocated_people,
          id: track.id,
          name: track.title
        }
      end)

    all_allocated_ids = Enum.flat_map(tracks, fn track -> Enum.map(track.people, & &1.id) end)
    unavailable = people |> Enum.filter(fn person -> person.unavailable end)
    unpaired = people |> Enum.filter(fn person -> person.id not in all_allocated_ids and not person.unavailable end)

    %{unpaired: unpaired, tracks: tracks, unavailable: unavailable}
  end

  # # # people

  def persons_for(project_id: project_id) do
    query = from(p in Person, where: p.project_id == ^project_id)
    Repo.all(query)
  end

  def mark_available_to_pair(person_id) do
    person = get_person!(person_id)

    person
    |> Person.changeset(%{unavailable: false})
    |> Repo.update!()
  end

  def mark_unavailable_to_pair(person_id) do
    person = get_person!(person_id)

    person
    |> Person.changeset(%{unavailable: true})
    |> Repo.update!()
  end

  # # # allocations

  def allocate_person_to_track!(track_id, person_id) do
    today = Date.utc_today()
    {:ok, start_of_day} = NaiveDateTime.new(today, ~T[00:00:00])

    Repo.delete_all(from(a in Allocation, where: a.person_id == ^person_id and a.updated_at >= ^start_of_day))

    %Allocation{}
    |> Allocation.changeset(%{track_id: track_id, person_id: person_id})
    |> Repo.insert!()
  end

  def remove_person_from_track!(track_id, person_id) do
    today = Date.utc_today()
    {:ok, start_of_day} = NaiveDateTime.new(today, ~T[00:00:00])

    query =
      from(a in Allocation,
        where: a.track_id == ^track_id and a.person_id == ^person_id and a.updated_at >= ^start_of_day
      )

    [allocation | _rest] = Repo.all(query)

    Repo.delete!(allocation)
  end

  def allocations_for_track(track_id) do
    today = Date.utc_today()
    {:ok, start_of_day} = NaiveDateTime.new(today, ~T[00:00:00])
    query = from(a in Allocation, where: a.track_id == ^track_id and a.updated_at >= ^start_of_day)
    Repo.all(query)
  end

  def reset_allocations_for_the_day(project_id) do
    today = Date.utc_today()
    {:ok, start_of_day} = NaiveDateTime.new(today, ~T[00:00:00])

    track_ids =
      tracks_for(project_id: project_id)
      |> Enum.map(& &1.id)

    query = from(a in Allocation, where: a.track_id in ^track_ids and a.updated_at >= ^start_of_day)

    Repo.delete_all(query)
  end

  @doc """
  Creates a person for a given project.

  """
  def create_person(attrs \\ %{}) do
    %Person{}
    |> Person.changeset(attrs)
    |> Repo.insert()
  end

  # tracks

  def create_track(attrs) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  def get_track!(id) do
    Repo.get!(Track, id)
  end

  def tracks_for(project_id: project_id) do
    query = from(t in Track, where: t.project_id == ^project_id)
    Repo.all(query)
  end

  def update_track_title!(track, new_title) do
    track
    |> Track.changeset(%{"title" => new_title})
    |> Repo.update!()
  end

  # # # Pairing Arrangements

  @shuffler Application.compile_env(:one_true_pairing, :shuffler)

  def decide_pairs(state) do
    Pairing.decide_pairs(state, @shuffler)
  end

  # # # Crud ahoy hoy

  @doc """
  Returns the list of projects.

  ## Examples

      iex> list_projects()
      [%Project{}, ...]

  """
  def list_projects do
    Repo.all(Project)
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(123)
      %Project{}

      iex> get_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project!(id), do: Repo.get!(Project, id)

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%{field: value})
      {:ok, %Project{}}

      iex> create_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

      iex> delete_project(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{data: %Project{}}

  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  alias OneTruePairing.Projects.Person

  @doc """
  Returns the list of people.

  ## Examples

      iex> list_people()
      [%Person{}, ...]

  """
  def list_people do
    Repo.all(Person)
  end

  @doc """
  Gets a single person.

  Raises `Ecto.NoResultsError` if the Person does not exist.

  ## Examples

      iex> get_person!(123)
      %Person{}

      iex> get_person!(456)
      ** (Ecto.NoResultsError)

  """
  def get_person!(id), do: Repo.get!(Person, id)

  @doc """
  Updates a person.

  ## Examples

      iex> update_person(person, %{field: new_value})
      {:ok, %Person{}}

      iex> update_person(person, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_person(%Person{} = person, attrs) do
    person
    |> Person.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a person.

  ## Examples

      iex> delete_person(person)
      {:ok, %Person{}}

      iex> delete_person(person)
      {:error, %Ecto.Changeset{}}

  """
  def delete_person(%Person{} = person) do
    Repo.delete(person)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking person changes.

  ## Examples

      iex> change_person(person)
      %Ecto.Changeset{data: %Person{}}

  """
  def change_person(%Person{} = person, attrs \\ %{}) do
    Person.changeset(person, attrs)
  end
end
