defmodule OneTruePairing.Pairing do
  # @related [test](test/one_true_pairing/pairing_test.exs)

  # shuffle the people
  # consider each track in order
  # place the people we need to get 2
  # leave any others remaining

  def decide_pairs(%{unpaired: unpaired, tracks: tracks} = state, shuffler) do
    shuffled = unpaired |> shuffler.()

    {assignments, unpaired} = decide_recursively(tracks, shuffled)

    state
    |> Map.put(:arrangements, assignments)
    |> Map.put(:unpaired, unpaired)
  end

  # # # algorithms for shuffling a list

  @doc "used in unit tests"
  def identity_shuffle(list), do: list

  @doc "used in the real application"
  def shuffle(list) do
    Enum.shuffle(list)
  end

  # # # private

  defp decide_recursively([], people), do: {[], people}
  defp decide_recursively(tracks, []), do: {tracks, []}

  defp decide_recursively([track | other_tracks], people) do
    {allocation, not_yet_paired} =
      case length(track.people) do
        0 ->
          {pair, remaining_people} = Enum.split(people, 2)
          {pair, remaining_people}

        1 ->
          {head, remaining_people} = Enum.split(people, 1)
          {track.people ++ head, remaining_people}

        _ ->
          {track.people, people}
      end

    {other_allocations, unpaired} = decide_recursively(other_tracks, not_yet_paired)

    # nb: this could be converted into a tail recursive function
    # if we could turn this into a reduce, accumulating the 
    # allocations and unpaired people as we go
    # but for the size of our current use case this is fine
    {[allocation | other_allocations], unpaired}
  end
end
