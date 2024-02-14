defmodule OneTruePairing.Pairing do
  # @related [test](test/one_true_pairing/pairing_test.exs)

  def decide_pairs(%{unpaired: unpaired, arrangements: _assignments, tracks: tracks} = state, shuffler) do
    shuffled = unpaired |> shuffler.()
    {to_pair, remaining} = Enum.split(shuffled, length(tracks) * 2)

    assignments = Enum.chunk_every(to_pair, 2)

    state
    |> Map.put(:arrangements, assignments)
    |> Map.put(:unpaired, remaining)
  end

  @doc "used in unit tests"
  def identity_shuffle(list), do: list

  @doc "used in the real application"
  def shuffle(list) do
    Enum.shuffle(list)
  end

  def reset_pairs(%{unpaired: unpaired, arrangements: assignments} = state) do
    state
    |> Map.put(:arrangements, [])
    |> Map.put(:unpaired, assignments |> List.flatten() |> Enum.concat(unpaired))
  end
end
