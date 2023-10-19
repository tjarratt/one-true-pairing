defmodule OneTruePairing.PairingTest do
  use OneTruePairing.DataCase, async: true

  test "pair_up/1" do
    folk = ["Alice", "Bob", "Carol", "Dan"]

    arrangement = OneTruePairing.Pairing.decide_pairs(folk, fn x -> x end)

    assert arrangement == [["Alice", "Bob"], ["Carol", "Dan"]]
  end
end
