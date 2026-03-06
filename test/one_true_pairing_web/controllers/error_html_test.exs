defmodule OneTruePairingWeb.ErrorHTMLTest do
  use OneTruePairingWeb.ConnCase, async: true

  import Expect, only: [expect: 2]
  import Expect.Matchers, only: [equal: 1]
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    rendered = render_to_string(OneTruePairingWeb.ErrorHTML, "404", "html", [])

    expect(rendered, to: equal("Not Found"))
  end

  test "renders 500.html" do
    rendered = render_to_string(OneTruePairingWeb.ErrorHTML, "500", "html", [])

    expect(rendered, to: equal("Internal Server Error"))
  end
end
