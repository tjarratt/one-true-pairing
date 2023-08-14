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

    assert list =~ "Bob"
    assert list =~ "Alice"
    assert list =~ "Carol"
  end
end
