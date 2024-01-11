defmodule OneTruePairingWeb.Router do
  import Plug.BasicAuth

  use OneTruePairingWeb, :router

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
    end

    live "/", Live.PairView, :index
    live "/pairing", Live.PairView, :index
    live "/example", Live.ExampleView, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", OneTruePairingWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:one_true_pairing, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OneTruePairingWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
