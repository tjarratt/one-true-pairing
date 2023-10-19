defmodule OneTruePairingWeb.PairingLiveTest do
  use OneTruePairingWeb.ConnCase

  import Phoenix.LiveViewTest

  test "it has a title", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/pairing")

    header = html |> HtmlQuery.find("h2") |> HtmlQuery.text()

    assert header =~ "Let's pair today"
  end

  test "it renders the list of people to pair up", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/pairing")

    list = html |> HtmlQuery.find!("#pairing_list") |> HtmlQuery.text()

    assert list =~ "Konstantinos"
    assert list =~ "Freja"
    assert list =~ "Andrew"
    assert list =~ "Jon"
    assert list =~ "Sarah"
    assert list =~ "Tim"
  end

  test "it renders a place to assign people to a track of work", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/pairing")

    list = html |> HtmlQuery.all(test_role: "track-of-work") |> 
    Enum.map(fn elem -> HtmlQuery.find!(elem, test_role: "track-name") end) |> Enum.map(fn elem -> HtmlQuery.attr(elem, "value") end)

    assert Enum.member?(list, "Inland")
    assert Enum.member?(list, "Emissions Calculations")
    assert Enum.member?(list, "Energy Bank")
  end
end
