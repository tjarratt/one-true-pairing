defmodule OneTruePairingWeb.PairingLiveTest do
  use OneTruePairingWeb.ConnCase

  import HtmlQuery
  import Phoenix.LiveViewTest

  test "it has a title", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/pairing")

    header = html |> HtmlQuery.find("h2") |> text

    assert header =~ "Let's pair today"
  end
end
