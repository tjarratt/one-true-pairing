defmodule OneTruePairing.Pairing do
  def decide_pairs(people, tracks, shuffler) do
    shuffled = people |> shuffler.()
    {to_pair, remaining} = Enum.split(shuffled, length(tracks) * 2)

    assignments = Enum.chunk_every(to_pair, 2)

    {remaining, assignments}
  end

  def identity_shuffle(list), do: list

  def shuffle(list) do
    Enum.shuffle(list)
  end
end
