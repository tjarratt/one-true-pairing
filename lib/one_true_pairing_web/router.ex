defmodule OneTruePairingWeb.Router do
  import Plug.BasicAuth

  use OneTruePairingWeb, :router
  use ErrorTracker.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OneTruePairingWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug(:basic_auth,
      username: "nrg",
      password: Application.compile_env!(:one_true_pairing, :basic_auth_password)
    )
  end

  scope "/", OneTruePairingWeb do
    pipe_through [:browser, :auth]

    resources "/projects", ProjectController do
      resources "/persons", PersonController
      live "/pairing", Live.PairView, :index
    end

    live "/", Live.HomeView, :index
  end

  import Phoenix.LiveDashboard.Router

  scope "/dev" do
    pipe_through [:browser, :auth]

    live_dashboard "/dashboard", metrics: OneTruePairingWeb.Telemetry
  end

  scope "/error_tracker" do
    pipe_through [:browser, :auth]

    error_tracker_dashboard("/")
  end
end
