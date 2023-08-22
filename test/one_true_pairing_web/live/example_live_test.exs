defmodule OneTruePairingWeb.ExampleLiveTest do
  use OneTruePairingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/example")

    [view: view, html: html]
  end

  test "the page exists and has a title", %{html: html} do
    header = html |> HtmlQuery.find("h1") |> HtmlQuery.text()

    assert header == "What does your banana look like ?"
  end

  test "the page has reasonable banana ripeness choices", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/example")

    options = html |> HtmlQuery.all("option") |> Enum.map(fn opt -> HtmlQuery.attr(opt, "value") end)

    assert options == ["", "green", "yellow", "brown", "purple"]
  end

  describe "when the user picks their desired ripeness" do
    test "(green) means they should chill for a bit", %{view: view} do
      header = my_banana_is(view, "green") |> HtmlQuery.find("h1") |> HtmlQuery.text()

      assert "Whoa, slow down. It's as hard as a rock." == header
    end

    test "(yellow) means it's time to strike", %{view: view} do
      header = my_banana_is(view, "yellow") |> HtmlQuery.find("h1") |> HtmlQuery.text()

      assert "Go ahead. It's delicious !" == header
    end

    test "(brown) means you missed your change", %{view: view} do
      header = my_banana_is(view, "brown") |> HtmlQuery.find("h1") |> HtmlQuery.text()

      assert "Easy partner, that banana's seen better days" == header
    end

    test "(purple) means where did you get that bannaa ?", %{view: view} do
      header = my_banana_is(view, "purple") |> HtmlQuery.find("h1") |> HtmlQuery.text()

      assert "Where did you get that banana ?" == header
    end
  end

  defp my_banana_is(view, ripeness) do
    view |> element("form") |> render_change(%{ripeness: ripeness})
  end
end
