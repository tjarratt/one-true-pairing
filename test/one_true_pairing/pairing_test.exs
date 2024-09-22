defmodule OneTruePairing.PairingTest do
  # @related [impl](lib/one_true_pairing/pairing.ex)
  use OneTruePairing.DataCase, async: true

  import OneTruePairing.Pairing, only: [decide_pairs: 2, reset_pairs: 1]

  @folks ["Alice", "Bob", "Carol", "Dan"]
  @shuffler &Function.identity/1

  describe "assigning pairs" do
    test "when there are enough people for the tracks of work" do
      tracks = ["basket weaving", "swimming"]

      %{unpaired: unpaired, arrangements: arrangements} =
        decide_pairs(%{unpaired: @folks, unavailable: [], track_names: tracks}, @shuffler)

      assert arrangements == [["Alice", "Bob"], ["Carol", "Dan"]]
      assert unpaired == []
    end

    test "when there are more than 2 people per track of work" do
      tracks = ["Dancing"]

      %{unpaired: unpaired, arrangements: arrangements} =
        decide_pairs(%{unpaired: @folks, unavailable: [], track_names: tracks}, @shuffler)

      assert arrangements == [["Alice", "Bob"]]
      assert unpaired == ["Carol", "Dan"]
    end
  end

  describe "resetting pairs" do
    test "moves people out of tracks of work" do
      state = %{
        unpaired: [],
        unavailable: [],
        tracks: ["basket weaving", "swimming"],
        arrangements: [["Alice", "Bob"], ["Carol", "Dan"]]
      }

      new_state = reset_pairs(state)

      assert new_state == %{
               unpaired: ~w(Alice Bob Carol Dan),
               unavailable: [],
               tracks: ["basket weaving", "swimming"],
               arrangements: []
             }
    end

    test "does not move people out of 'unavailable'" do
      state = %{
        unpaired: [],
        unavailable: @folks,
        tracks: ["basket weaving", "swimming"],
        arrangements: []
      }

      new_state = reset_pairs(state)

      assert new_state == state
    end
  end
end
