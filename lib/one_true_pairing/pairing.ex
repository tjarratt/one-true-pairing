defmodule OneTruePairing.Pairing do
  # @related [test](test/one_true_pairing/pairing_test.exs)

  @doc """
    Decides pairs for the given tracks.

    A track may have as many people as you like it in (this is mobbing).
    This algorithm will attempt to place at most 2 people per track.

    First it shuffles the people, to inject some randomness.
    Then, for each track, assign up to two people to work on it.

    If a track has one person already in it, it assigns one more.
    If a track has two or more already in it, it assigns none.

    If a track has empty slots, but no one is left to assign, it does nothing.
  """

  def decide_pairs(%{unpaired: unpaired, tracks: tracks} = state, shuffler) do
    unpaired = unpaired |> shuffler.()
    tracks = tracks |> shuffler.()

    {assignments, unpaired} = decide_recursively(tracks, unpaired)

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

  # base case
  defp decide_recursively([], []), do: {[], []}

  # in case there are not enough tracks for the people, leave people unassigned
  defp decide_recursively([], people), do: {[], people}

  # in case there are not enough people for the tracks, some tracks of work are left unallocated
  defp decide_recursively([track | other_tracks], []) do
    {other_allocations, unpaired} = decide_recursively(other_tracks, [])

    {
      [{track, track.people} | other_allocations],
      unpaired
    }
  end

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
    {[{track, allocation} | other_allocations], unpaired}
  end
end
