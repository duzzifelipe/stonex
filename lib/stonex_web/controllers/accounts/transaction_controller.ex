defmodule StonexWeb.Accounts.TransactionController do
  @moduledoc """
  Endpoint for leading with money transfers, either
  for withdraws and transfering between accounts.

  The user must be authenticated and can only
  use an account id as debit account from an
  account he/she owns
  """

  use StonexWeb, :controller

  alias Stonex.Accounts.{Account, Repository}

  @spec withdraw(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def withdraw(conn, %{"account_id" => account_id} = params) do
    amount = Map.get(params, "amount")
    user = Guardian.Plug.current_resource(conn)

    case Repository.account_by_user(user, account_id) do
      %Account{} = account ->
        case perform_withdraw(account, amount) do
          {:ok, result} ->
            render(conn, "withdraw.json", %{account: result})

          {:error, changeset} ->
            render(conn, "withdraw.json", %{error: changeset})
        end

      nil ->
        render(conn, "account_not_found.json")
    end
  end

  defp perform_withdraw(_, amount) when not is_integer(amount) do
    {:error, "invalid amount to withdraw"}
  end

  defp perform_withdraw(account, amount) do
    Repository.withdraw_money(account, amount)
  end
end
