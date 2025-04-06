defmodule BasicAuthContractTest do
  use OneTruePairingWeb.ConnCase

  alias OneTruePairingWeb.Router

  import Expect
  import Expect.Matchers

  test "LiveView paths must all be secured behind basic auth", %{conn: conn} do
    subjects = modules() |> Enum.filter(&implementing_liveview/1)

    # ensure this test is actually testing at least ONE module
    expect(subjects) |> to_have_length(2)

    subjects
    # temporarily disable pair live view because it is a nested view
    # and we cannot build its path using RouteHelpers the same way
    # and we also need to know which project it is nested under (oy vey)
    |> Enum.filter(fn module -> module != OneTruePairingWeb.Live.PairView end)
    |> Enum.map(fn module -> assert_basic_auth!(module, conn) end)
  end

  defp modules() do
    {:ok, modules} = :application.get_key(:one_true_pairing, :modules)
    modules
  end

  defp implementing_liveview(module) do
    Phoenix.LiveView in behaviours(module)
  end

  defp behaviours(module) do
    module.module_info(:attributes)[:behaviour] || []
  end

  defp assert_basic_auth!(module, conn) do
    path =
      module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()
      |> (fn name -> name <> "_path" end).()
      |> String.to_atom()
      |> (fn atom -> apply(Router.Helpers, atom, [conn, :index]) end).()

    conn = delete_req_header(conn, "authorization") |> get(path)

    assert response(conn, :unauthorized), "Path #{path} should be protected by basic auth"
  end
end
