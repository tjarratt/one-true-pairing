defmodule OneTruePairing.PairingTest do
  use OneTruePairing.DataCase, async: true

  test "when there are enough people for the tracks of work" do
    folk = ["Alice", "Bob", "Carol", "Dan"]
    tracks = ["basket weaving", "swimming"]

    {unpaired, arrangements} = OneTruePairing.Pairing.decide_pairs(folk, tracks, fn x -> x end)

    assert arrangements == [["Alice", "Bob"], ["Carol", "Dan"]]
    assert unpaired == []
  end

  test "when there are more than 2 people per track of work" do
    folks = ["Alice", "Bob", "Carol"]
    tracks = ["Dancing"]

    {unpaired, arrangements} = OneTruePairing.Pairing.decide_pairs(folks, tracks, fn x -> x end)

    assert arrangements == [["Alice", "Bob"]]
    assert unpaired == ["Carol"]
  end
end
