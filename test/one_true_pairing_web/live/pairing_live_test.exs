defmodule OneTruePairingWeb.PairingLiveTest do
  use OneTruePairingWeb.ConnCase

  import Phoenix.LiveViewTest

  test "it has a title", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/pairing")

    header = html |> HtmlQuery.find("h1") |> HtmlQuery.text()

    assert header =~ "Let's pair today"
  end

  test "it renders the list of people available to pair", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/pairing")

    list = html |> HtmlQuery.find!("#pairing_list") |> HtmlQuery.text()

    assert list =~ "Sarah"
    assert list =~ "Andrew"
    assert list =~ "Konstantinos"
    assert list =~ "Jon"
    assert list =~ "Freja"
    assert list =~ "Tim"
  end

  test "it renders the tracks of work", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/pairing")

    list =
      html
      |> HtmlQuery.all(test_role: "track-of-work")
      |> Enum.map(fn elem -> HtmlQuery.find!(elem, test_role: "track-name") end)
      |> Enum.map(fn elem -> HtmlQuery.attr(elem, "value") end)

    assert Enum.member?(list, "Inland")
    assert Enum.member?(list, "Emissions Calculations")
    assert Enum.member?(list, "Energy Bank")
  end

  test "randomising pairs", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pairing")

    html =
      view
      |> element("button", "Randomize pairs")
      |> render_click()

    [first_pair, second_pair, third_pair] =
      html |> HtmlQuery.all(test_role: "track-of-work") |> Enum.map(&HtmlQuery.text/1)

    assert first_pair =~ "Sarah"
    assert first_pair =~ "Andrew"

    assert second_pair =~ "Konstantinos"
    assert second_pair =~ "Jon"

    assert third_pair =~ "Freja"
    assert third_pair =~ "Tim"

    unpaired_folks = html |> HtmlQuery.find!(test_role: "unpaired") |> HtmlQuery.text()

    assert unpaired_folks == "Nikhil"
  end

  test "resetting pairs", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/pairing")

    view
    |> element("button", "Randomize pairs")
    |> render_click()

    html =
      view
      |> element("button", "Reset pairs")
      |> render_click()

    list = html |> HtmlQuery.find!("#pairing_list") |> HtmlQuery.text()

    assert list =~ "Sarah"
    assert list =~ "Andrew"
    assert list =~ "Konstantinos"
    assert list =~ "Jon"
    assert list =~ "Freja"
    assert list =~ "Tim"

    [first_pair, second_pair, third_pair] =
      html |> HtmlQuery.all(test_role: "track-of-work") |> Enum.map(&HtmlQuery.text/1)

    assert first_pair == ""
    assert second_pair == ""
    assert third_pair == ""
  end
end
