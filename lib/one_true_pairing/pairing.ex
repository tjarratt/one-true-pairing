defmodule OneTruePairing.Pairing do
  def decide_pairs(people, _tracks, shuffler) do
    assignments = people
      |> shuffler.()
      |> Enum.chunk_every(2)

    {[], assignments}
  end

  def identity_shuffle(list), do: list

  def shuffle(list) do
    Enum.shuffle(list)
  end
end
