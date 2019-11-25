defmodule StonexWeb.Accounts.TransactionView do
  use StonexWeb, :view

  alias StonexWeb.ErrorHelpers

  def render("withdraw.json", %{account: account}) do
    %{account: account, error: false}
  end

  def render("withdraw.json", %{error: error}) do
    error = ErrorHelpers.parse_error(error)
    %{account: nil, error: error}
  end

  def render("account_not_found.json", _data) do
    %{error: "account not found"}
  end
end
