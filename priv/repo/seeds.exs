# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     OneTruePairing.Repo.insert!(%OneTruePairing.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

fellowship = OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Project{name: "Fellowship"})

OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Sam", project_id: fellowship.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Gandalf", project_id: fellowship.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Gimli", project_id: fellowship.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Legolas", project_id: fellowship.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Aragorn", project_id: fellowship.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Boromir", project_id: fellowship.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Frodo", project_id: fellowship.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Pippin", project_id: fellowship.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Merry", project_id: fellowship.id})

OneTruePairing.Projects.create_track(%{title: "Hobbit babysitting", project_id: fellowship.id})
OneTruePairing.Projects.create_track(%{title: "Potatoe boiling", project_id: fellowship.id})

test_space = OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Project{name: "Test Space"})

OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Alice", project_id: test_space.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Bob", project_id: test_space.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Carol", project_id: test_space.id})

OneTruePairing.Projects.create_track(%{title: nil, project_id: test_space.id})
OneTruePairing.Projects.create_track(%{title: "   ", project_id: test_space.id})
OneTruePairing.Projects.create_track(%{title: "Mobbing", project_id: test_space.id})
