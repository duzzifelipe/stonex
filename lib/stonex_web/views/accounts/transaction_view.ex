defmodule StonexWeb.Accounts.TransactionView do
  use StonexWeb, :view

  alias StonexWeb.ErrorHelpers

  @not_found "account not found"

  def render("withdraw.json", %{account: account}) do
    %{account: account, error: false}
  end

  def render("withdraw.json", %{error: error}) do
    error = ErrorHelpers.parse_error(error)
    %{account: nil, error: error}
  end

  def render("transfer.json", %{debit_account: acc_1, credit_account: acc_2}) do
    %{debit_account: acc_1, credit_account: acc_2, error: %{debit: nil, credit: nil}}
  end

  def render("transfer.json", %{error: %{debit: debit, credit: credit}}) do
    debit = ErrorHelpers.parse_error(debit)
    credit = ErrorHelpers.parse_error(credit)

    %{debit_account: nil, credit_account: nil, error: %{debit: debit, credit: credit}}
  end

  def render("account_not_found.json", _data) do
    %{error: @not_found}
  end

  def render("accounts_not_found.json", %{debit: acc_1, credit: acc_2}) do
    cond do
      is_nil(acc_1) && is_nil(acc_2) ->
        %{error: %{debit: @not_found, credit: @not_found}}

      is_nil(acc_1) ->
        %{error: %{debit: @not_found, credit: nil}}

      is_nil(acc_2) ->
        %{error: %{debit: nil, credit: @not_found}}
    end
  end
end
