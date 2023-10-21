defmodule OneTruePairing.PairingTest do
  use OneTruePairing.DataCase, async: true

  test "pair_up/1" do
    folk = ["Alice", "Bob", "Carol", "Dan"]
    tracks = ["basket weaving", "swimming"]

    {unpaired, arrangements} = OneTruePairing.Pairing.decide_pairs(folk, tracks, fn x -> x end)

    assert arrangements == [["Alice", "Bob"], ["Carol", "Dan"]]
    assert unpaired == []
  end
end
