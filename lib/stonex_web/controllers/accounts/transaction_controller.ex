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

  @doc """
  Given an authenticated user and an account_id
  related to an account that this user owns,
  calls the action for withdrawing money from
  that account
  """
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

  @doc """
  Receives two accounts ids from request path, the first
  one belonging to the current user (that will be debited)
  and a secod one to be credited
  """
  @spec transfer(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def transfer(
        conn,
        %{"account_id" => account_id, "credit_account_id" => credit_account_id} = params
      ) do
    amount = Map.get(params, "amount")
    user = Guardian.Plug.current_resource(conn)

    debit_account = Repository.account_by_user(user, account_id)
    credit_account = Repository.account_by_id(credit_account_id)

    if not is_nil(debit_account) && not is_nil(credit_account) do
      case Repository.transfer_money(debit_account, credit_account, amount) do
        {:ok, {acc_1, acc_2}} ->
          render(conn, "transfer.json", %{debit_account: acc_1, credit_account: acc_2})

        {:error, {ch_1, ch_2}} ->
          render(conn, "transfer.json", %{error: %{debit: ch_1, credit: ch_2}})
      end
    else
      render(conn, "accounts_not_found.json", %{debit: debit_account, credit: credit_account})
    end
  end

  defp perform_withdraw(_, amount) when not is_integer(amount) do
    {:error, "invalid amount to withdraw"}
  end

  defp perform_withdraw(account, amount) do
    Repository.withdraw_money(account, amount)
  end
end
