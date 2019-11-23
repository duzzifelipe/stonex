defmodule StonexWeb.AuthenticationController do
  @moduledoc """
  Endpoints for interacting with user schema.

  It can create an account or authenticate an
  user to generate his/her token
  """
  use StonexWeb, :controller

  alias Stonex.Users.Repository

  @doc """
  Receives the data required by user schema to create
  a new user account.
  """
  @spec signup(Plug.Conn.t(), %{
          email: binary(),
          first_name: binary(),
          last_name: nil | binary(),
          password: binary(),
          password_confirmation: binary(),
          registration_id: binary(),
          agency: pos_integer()
        }) :: Plug.Conn.t()
  def signup(conn, params) do
    agency = Map.get(params, "agency", 1)

    case Repository.signup_with_account(params, agency) do
      {:ok, {user, account}} ->
        conn
        |> render("signup.json", %{user: user, account: account, error: nil})

      {:error, {error_1, error_2}} ->
        conn
        |> put_status(400)
        |> render("signup.json", %{
          user: nil,
          account: nil,
          error: %{user: error_1, account: error_2}
        })
    end
  end
end
