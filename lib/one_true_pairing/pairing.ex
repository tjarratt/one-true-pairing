defmodule OneTruePairing.Pairing do
  def decide_pairs(people, shuffler) do
    people
    |> shuffler.()
    |> Enum.chunk_every(2)
  end
end
