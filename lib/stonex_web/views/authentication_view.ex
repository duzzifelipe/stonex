defmodule StonexWeb.AuthenticationView do
  use StonexWeb, :view

  alias StonexWeb.ErrorHelpers

  def render("signup.json", %{user: user, account: account, auth: auth, error: nil}) do
    %{user: user, account: account, auth: auth, error: nil}
  end

  def render("signup.json", %{
        user: nil,
        account: nil,
        auth: nil,
        error: %{user: error_1, account: error_2}
      }) do
    error_1 = ErrorHelpers.parse_error(error_1)
    error_2 = ErrorHelpers.parse_error(error_2)
    %{user: nil, auth: nil, account: nil, error: %{user: error_1, account: error_2}}
  end

  def render("login.json", %{user: user, auth: auth, error: nil}) do
    %{user: user, auth: auth, error: nil}
  end

  def render("login.json", %{user: nil, auth: nil, error: error}) do
    %{user: nil, auth: nil, error: ErrorHelpers.parse_error(error)}
  end
end
