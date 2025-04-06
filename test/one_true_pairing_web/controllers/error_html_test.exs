defmodule OneTruePairingWeb.ErrorHTMLTest do
  use OneTruePairingWeb.ConnCase, async: true

  import Expect
  import Expect.Matchers
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    rendered = render_to_string(OneTruePairingWeb.ErrorHTML, "404", "html", [])

    expect(rendered) |> to_equal("Not Found")
  end

  test "renders 500.html" do
    rendered = render_to_string(OneTruePairingWeb.ErrorHTML, "500", "html", [])

    expect(rendered) |> to_equal("Internal Server Error")
  end
end
