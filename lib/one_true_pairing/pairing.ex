defmodule OneTruePairing.Pairing do
  def decide_pairs(people, shuffler) do
    people
    |> shuffler.()
    |> Enum.chunk_every(2)
  end

  def identity_shuffle(list), do: list

  def shuffle(list) do
    Enum.shuffle(list)
  end
end
