defmodule StonexWeb.AuthenticationController do
  @moduledoc """
  Endpoints for interacting with user schema.

  It can create an account or authenticate an
  user to generate his/her token
  """
  use StonexWeb, :controller

  alias Stonex.Users.Repository
  alias Stonex.Users.Guardian

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
        |> render("signup.json", %{
          user: user,
          auth: generate_auth(user),
          account: account,
          error: nil
        })

      {:error, {error_1, error_2}} ->
        conn
        |> put_status(400)
        |> render("signup.json", %{
          user: nil,
          auth: nil,
          account: nil,
          error: %{user: error_1, account: error_2}
        })
    end
  end

  @spec login(Plug.Conn.t(), %{email: binary(), password: binary()}) :: Plug.Conn.t()
  def login(conn, %{"email" => email, "password" => password}) do
    case Repository.login(email, password) do
      {:ok, user} ->
        conn
        |> render("login.json", %{user: user, auth: generate_auth(user), error: nil})

      {:error, error} ->
        conn
        |> put_status(400)
        |> render("login.json", %{user: nil, auth: nil, error: error})
    end
  end

  defp generate_auth(user) do
    {:ok, token, _} = Guardian.encode_and_sign(user)
    token
  end
end
