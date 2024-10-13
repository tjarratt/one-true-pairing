defmodule OneTruePairing.PairingTest do
  # @related [impl](lib/one_true_pairing/pairing.ex)
  use OneTruePairing.DataCase, async: true

  import OneTruePairing.Pairing, only: [decide_pairs: 2]

  @folks ["Alice", "Bob", "Carol", "Dan"]
  @shuffler &Function.identity/1

  describe "assigning pairs" do
    test "when there are enough people for the tracks of work" do
      tracks = [
        basket_weaving = track_fixture(name: "basket weaving"), 
        swimming = track_fixture(name: "swimming")
      ]

      %{unpaired: unpaired, arrangements: arrangements} =
        decide_pairs(%{unpaired: @folks, unavailable: [], tracks: tracks}, @shuffler)

      assert arrangements == [
      {basket_weaving, ["Alice", "Bob"]}, 
      {swimming, ["Carol", "Dan"]}
      ]
      assert unpaired == []
    end

    test "when there are more than 2 people per track of work" do
      tracks = [track = track_fixture(name: "Dancing")]

      %{unpaired: unpaired, arrangements: arrangements} =
        decide_pairs(%{unpaired: @folks, unavailable: [], tracks: tracks}, @shuffler)

      assert arrangements == [{track, ["Alice", "Bob"]}]
      assert unpaired == ["Carol", "Dan"]
    end

    test "when some folks are already assigned to a track" do
      tracks = [working = track_fixture(name: "Working", people: ["Dan"]), sleeping = track_fixture(name: "Sleeping")]

      %{unpaired: unpaired, arrangements: arrangements} =
        decide_pairs(
          %{
            unpaired: ["Alice", "Bob", "Carol"],
            tracks: tracks,
            unavailable: []
          },
          @shuffler
        )

      assert unpaired == []

      assert arrangements == [
               {working, ["Dan", "Alice"]},
               {sleeping, ["Bob", "Carol"]}
             ]
    end

    test "when there are not enough people for the work -- it pairs people up, leaving some tracks unassigned" do
      tracks = [
        track = track_fixture(name: "Important"),
        track_fixture(name: "Nice to have")
      ]

      %{unpaired:  unpaired, arrangements: arrangements} =
        decide_pairs(%{unpaired: ["Alice", "Bob"], tracks: tracks, unavailable: []}, @shuffler)

      assert arrangements == [
        {track, ["Alice", "Bob"]}
      ]
      assert unpaired == []
    end
  end

  defp track_fixture(opts) do
    given_name = Keyword.fetch!(opts, :name)
    people = Keyword.get(opts, :people, [])

    %{name: given_name, people: people}
  end
end
