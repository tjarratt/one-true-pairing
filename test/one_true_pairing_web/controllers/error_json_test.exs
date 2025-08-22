defmodule OneTruePairingWeb.ErrorJSONTest do
  use ExUnit.Case, async: true

  import Expect
  import Expect.Matchers

  test "renders 404" do
    response = OneTruePairingWeb.ErrorJSON.render("404.json", %{})
    expect(response, to: equal(%{errors: %{detail: "Not Found"}}))
  end

  test "renders 500" do
    response = OneTruePairingWeb.ErrorJSON.render("500.json", %{})
    expect(response, to: equal(%{errors: %{detail: "Internal Server Error"}}))
  end
end
