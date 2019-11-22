defmodule Stonex.Accounts.Repository do
  @moduledoc """
  This module implements all interfaces
  to interact with bank accounts: create,
  withdraw and transfer money
  """

  import Ecto.Query, warn: false

  alias Stonex.Repo
  alias Stonex.Accounts.{Account, AccountHistory}
  alias Stonex.Users.User

  # default account balance on creation is 1.000,00
  @default_balance 100_000

  @doc """
  Receives an user instance and an agency number
  and create a new account for it.

  Account number is generated by getting the last
  created account number for the given agency and
  summing up 1.

  Initial balance is set to a default configured
  value.

  ## Examples
      iex> {:ok, created_user} = Stonex.Users.Repository.signup(%{
      ...>   email: "duzzifelipe@gmail.com",
      ...>   first_name: "Felipe",
      ...>   last_name: "Duzzi",
      ...>   password: "sT0n3TEST",
      ...>   password_confirmation: "sT0n3TEST",
      ...>   registration_id: "397.257.568-86"
      ...> })
      ...> {:ok, account} = Stonex.Accounts.Repository.create_account(
      ...>   created_user,
      ...>   1
      ...> )
      ...> assert account.agency == 1
      true
  """

  @spec create_account(User.t(), number) :: Account.t()
  def create_account(%User{id: user_id}, agency) when is_number(agency) do
    number = get_next_account_number(agency)

    %Account{}
    |> Account.create_changeset(%{
      user_id: user_id,
      agency: agency,
      number: number,
      balance: @default_balance
    })
    |> Repo.insert()
  end

  @doc """
  Receives an account struct where amount
  will be debited.

  Amount is represented by an integer using
  two digits as decimal places

  ## Examples

      iex> {:ok, created_user} = Stonex.Users.Repository.signup(%{
      ...>   email: "duzzifelipe@gmail.com",
      ...>   first_name: "Felipe",
      ...>   last_name: "Duzzi",
      ...>   password: "sT0n3TEST",
      ...>   password_confirmation: "sT0n3TEST",
      ...>   registration_id: "397.257.568-86"
      ...> })
      ...> {:ok, account} = Stonex.Accounts.Repository.create_account(
      ...>   created_user,
      ...>   1
      ...> )
      ...> {:ok, account} = Stonex.Accounts.Repository.withdraw_money(
      ...>   account,
      ...>   200
      ...> )
      ...> account.balance
      99800
  """
  @spec withdraw_money(Stonex.Accounts.Account.t(), integer) ::
          {:ok, Stonex.Accounts.Account.t()} | {:error, any}
  def withdraw_money(%Account{} = account, amount) do
    changeset = Account.update_balance_changeset(account, :debit, amount)

    if changeset.valid? do
      Repo.update(changeset)
    else
      {:error, changeset.errors}
    end
  end

  @doc """
  Receives two accounts and an amount to be sent
  from first account to the second account.

  Amount is represented by an integer using
  two digits as decimal places

  ## Examples

      iex> {:ok, created_user} = Stonex.Users.Repository.signup(%{
      ...>   email: "duzzifelipe@gmail.com",
      ...>   first_name: "Felipe",
      ...>   last_name: "Duzzi",
      ...>   password: "sT0n3TEST",
      ...>   password_confirmation: "sT0n3TEST",
      ...>   registration_id: "397.257.568-86"
      ...> })
      ...> {:ok, account_1} = Stonex.Accounts.Repository.create_account(
      ...>   created_user,
      ...>   1
      ...> )
      ...> {:ok, account_2} = Stonex.Accounts.Repository.create_account(
      ...>   created_user,
      ...>   1
      ...> )
      ...> {:ok, {new_1, new_2}} = Stonex.Accounts.Repository.transfer_money(
      ...>   account_1,
      ...>   account_2,
      ...>   200
      ...> )
      ...> [new_1.balance, new_2.balance]
      [99800, 100200]
  """
  @spec transfer_money(Stonex.Accounts.Account.t(), Stonex.Accounts.Account.t(), integer) :: any
  def transfer_money(%Account{} = account_debit, %Account{} = account_credit, amount) do
    changeset_debit = Account.update_balance_changeset(account_debit, :debit, amount)
    changeset_credit = Account.update_balance_changeset(account_credit, :credit, amount)

    if changeset_debit.valid? && changeset_credit.valid? do
      Repo.transaction(fn ->
        new_debit = Repo.update!(changeset_debit)
        new_credit = Repo.update!(changeset_credit)

        {new_debit, new_credit}
      end)
    else
      {:error, {changeset_debit.errors, changeset_credit.errors}}
    end
  end

  defp get_next_account_number(agency) do
    last_account = get_one_account_by_digit(agency)

    if is_nil(last_account) do
      1
    else
      last_account.number + 1
    end
  end

  defp get_one_account_by_digit(agency) do
    from(a in Account, where: a.agency == ^agency, order_by: [desc: :number])
    |> Repo.one()
  end

  defp register_transaction_history(%Account{id: account_id}, type, amount) do
    params = %{
      account_id: account_id,
      amount: amount,
      type: type
    }

    AccountHistory.create_changeset(%AccountHistory{}, params)
    |> Repo.insert!()
  end
end
