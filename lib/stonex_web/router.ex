defmodule StonexWeb.Router do
  use StonexWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :with_auth do
    plug Guardian.Plug.Pipeline,
      module: Stonex.Users.Guardian,
      error_handler: StonexWeb.GuardianErrorHandler

    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end

  scope "/api", StonexWeb do
    pipe_through :api

    post "/signup", AuthenticationController, :signup
    post "/login", AuthenticationController, :login

    scope "/accounts", Accounts do
      pipe_through :with_auth

      get "/:account_id/history", HistoryController, :index

      post "/:account_id/transactions/withdraw", TransactionController, :withdraw
    end
  end
end
