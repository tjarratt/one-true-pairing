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

project = OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Project{name: "Fellowship"})

OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Sam", project_id: project.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Gandalf", project_id: project.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Gimli", project_id: project.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Legolas", project_id: project.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Aragorn", project_id: project.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Boromir", project_id: project.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Frodo", project_id: project.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Pippin", project_id: project.id})
OneTruePairing.Repo.insert!(%OneTruePairing.Projects.Person{name: "Merry", project_id: project.id})
