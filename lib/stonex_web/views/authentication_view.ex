defmodule StonexWeb.AuthenticationView do
  use StonexWeb, :view

  alias StonexWeb.ErrorHelpers

  def render("signup.json", %{user: user, account: account, error: nil}) do
    %{user: user, account: account, error: nil}
  end

  def render("signup.json", %{user: nil, account: nil, error: %{user: error_1, account: error_2}}) do
    error_1 = parse_error(error_1)
    error_2 = parse_error(error_2)
    %{user: nil, account: nil, error: %{user: error_1, account: error_2}}
  end

  defp parse_error(error) do
    case error do
      %Ecto.Changeset{} ->
        ErrorHelpers.translate_errors(error)

      _ ->
        error
    end
  end
end
