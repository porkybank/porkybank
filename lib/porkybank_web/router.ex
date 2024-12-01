defmodule PorkybankWeb.Router do
  use PorkybankWeb, :router

  import PorkybankWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PorkybankWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user

    plug LiveViewNative.SessionPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
  end

  pipeline :require_setup do
    plug PorkybankWeb.Plugs.RequirePlaidAccount
    plug PorkybankWeb.Plugs.RequireIncome
    plug PorkybankWeb.Plugs.RequireExpense
  end

  pipeline :require_admin do
    plug PorkybankWeb.Plugs.RequireAdmin
  end

  scope "/", PorkybankWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :new_user_setup,
      on_mount: [{PorkybankWeb.UserAuth, :ensure_authenticated}] do
      live "/setup/:step", SetupLive, :setup
    end
  end

  scope "/", PorkybankWeb do
    pipe_through [:browser, :require_authenticated_user, :require_setup]

    # get "/", PageController, :home

    live_session :authenticated, on_mount: [{PorkybankWeb.UserAuth, :ensure_authenticated}] do
      live "/overview", OverviewLive
      live "/overview/income", OverviewLive, :income
      live "/overview/expense", OverviewLive, :expense
      live "/overview/category", OverviewLive, :category
      live "/transactions", TransactionsLive
      live "/transactions/new", TransactionsLive, :new
      live "/transactions/category", TransactionsLive, :category
      live "/transactions/:id/category", TransactionsLive, :category
      live "/transactions/:id/edit", TransactionsLive, :edit
    end
  end

  scope "/example", PorkybankWeb do
    pipe_through [:browser]

    live "/overview", OverviewLive, :example
    live "/transactions", TransactionsLive, :example
  end

  scope "/ios", PorkybankWeb do
    pipe_through [:browser, :require_ios_user]

    live "/", HomeLive, :index
    live "/overview", OverviewLive, :index
  end

  scope "/admin", PorkybankWeb do
    pipe_through [:browser, :require_admin]

    live "/users", Admin.AdminUsersLive
    live "/categories", Admin.AdminCategoryLive
    live "/custom-pfcs", Admin.AdminCustomPfcLive
    live "/plaid-accounts", Admin.AdminPlaidAccountLive
    live "/ignored-transactions", Admin.AdminIgnoredTransactionsLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", PorkybankWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:porkybank, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PorkybankWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", PorkybankWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{PorkybankWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/", LandingPageLive
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", PorkybankWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PorkybankWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/category/:id", UserSettingsLive, :category
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", PorkybankWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{PorkybankWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
