defmodule StonexWeb.Router do
  use StonexWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", StonexWeb do
    pipe_through :api
  end
end
