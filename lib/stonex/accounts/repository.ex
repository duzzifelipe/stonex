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
  alias Stonex.Services.DebitMailer

  # default account balance on creation is 1.000,00
  @default_balance 100_000

  @one_day_seconds 60 * 60 * 24

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
  @spec create_account(User.t(), pos_integer()) ::
          {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create_account(%User{id: user_id}, agency) when is_number(agency) do
    number = get_next_account_number(agency)

    changeset =
      %Account{}
      |> Account.create_changeset(%{
        user_id: user_id,
        agency: agency,
        number: number,
        balance: @default_balance
      })

    case Repo.insert(changeset) do
      {:ok, account} ->
        register_transaction_history(account, "credit", account.balance)
        {:ok, account}

      error ->
        error
    end
  end

  def create_account(_, _), do: {:error, "invalid agency number"}

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
      ...> account = Map.put(account, :user, created_user)
      ...> {:ok, account} = Stonex.Accounts.Repository.withdraw_money(
      ...>   account,
      ...>   200
      ...> )
      ...> account.balance
      99800
  """
  @spec withdraw_money(Stonex.Accounts.Account.t(), pos_integer()) ::
          {:ok, Stonex.Accounts.Account.t()} | {:error, any}
  def withdraw_money(%Account{user: %User{} = user} = account, amount) do
    changeset = Account.update_balance_changeset(account, :debit, amount)

    if changeset.valid? do
      case Repo.update(changeset) do
        {:ok, updated} ->
          register_transaction_history(updated, "debit", amount)
          DebitMailer.send_debit_email(user, account, amount)
          {:ok, updated}

        error ->
          error
      end
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
      ...> account_1 = Map.put(account_1, :user, created_user)
      ...> {:ok, {new_1, new_2}} = Stonex.Accounts.Repository.transfer_money(
      ...>   account_1,
      ...>   account_2,
      ...>   200
      ...> )
      ...> [new_1.balance, new_2.balance]
      [99800, 100200]
  """
  @spec transfer_money(Stonex.Accounts.Account.t(), Stonex.Accounts.Account.t(), pos_integer()) ::
          {:ok, Stonex.Accounts.Account.t(), Stonex.Accounts.Account.t()} | {:error, any(), any()}
  def transfer_money(%Account{user: user} = account_debit, %Account{} = account_credit, amount) do
    changeset_debit = Account.update_balance_changeset(account_debit, :debit, amount)
    changeset_credit = Account.update_balance_changeset(account_credit, :credit, amount)

    if changeset_debit.valid? && changeset_credit.valid? do
      Repo.transaction(fn ->
        new_debit = Repo.update!(changeset_debit)
        new_credit = Repo.update!(changeset_credit)

        register_transaction_history(new_debit, "debit", amount)
        register_transaction_history(new_credit, "credit", amount)

        DebitMailer.send_debit_email(user, account_debit, amount)

        {new_debit, new_credit}
      end)
    else
      {:error, {changeset_debit.errors, changeset_credit.errors}}
    end
  end

  @doc """
  Receives an account object and return
  a list of all transactions made by this
  account on an specific range, defined
  by the second argument:
  :all, :year, :month, :day

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
      ...> history = Stonex.Accounts.Repository.list_account_history(
      ...>   account, :all
      ...> )
      ...> Enum.count(history.items) == 1 && Enum.at(history.items, 0).amount === 100_000
      true
  """
  @spec list_account_history(Stonex.Accounts.Account.t(), atom()) ::
          %{
            items: list(Stonex.Accounts.AccountHistory.t()),
            total_debit: pos_integer(),
            total_credit: pos_integer()
          }
  def list_account_history(%Account{id: account_id}, :all) do
    Repo.all(account_history_query(account_id))
    |> put_history_accumulators()
  end

  def list_account_history(%Account{id: account_id}, type)
      when type == :year or type == :month or type == :day do
    min_date = build_min_date(type)

    from(h in account_history_query(account_id),
      where: h.inserted_at > ^min_date
    )
    |> Repo.all()
    |> put_history_accumulators()
  end

  @doc """
  Given a user object, finds an account
  that is related to this user, in order
  to validate ownership

  ## Examples

      iex> {:ok, user} = Stonex.Users.Repository.signup(%{
      ...>   email: "duzzifelipe@gmail.com",
      ...>   first_name: "Felipe",
      ...>   last_name: "Duzzi",
      ...>   password: "sT0n3TEST",
      ...>   password_confirmation: "sT0n3TEST",
      ...>   registration_id: "397.257.568-86"
      ...> })
      ...> {:ok, account} = Stonex.Accounts.Repository.create_account(
      ...>   user, 1
      ...> )
      ...> acc = Stonex.Accounts.Repository.account_by_user(user, account.id)
      ...> acc.id == account.id
      true
  """
  @spec account_by_user(User.t(), pos_integer()) :: Account.t() | nil
  def account_by_user(%User{id: user_id}, account_id) do
    from(a in Account, where: a.user_id == ^user_id and a.id == ^account_id)
    |> Repo.one()
  end

  @doc """
  Given an account id, retrieve the account from database

  ## Examples

      iex> {:ok, user} = Stonex.Users.Repository.signup(%{
      ...>   email: "duzzifelipe@gmail.com",
      ...>   first_name: "Felipe",
      ...>   last_name: "Duzzi",
      ...>   password: "sT0n3TEST",
      ...>   password_confirmation: "sT0n3TEST",
      ...>   registration_id: "397.257.568-86"
      ...> })
      ...> {:ok, account} = Stonex.Accounts.Repository.create_account(
      ...>   user, 1
      ...> )
      ...> acc = Stonex.Accounts.Repository.account_by_id(account.id)
      ...> acc.id == account.id
      true
  """
  @spec account_by_id(pos_integer) :: Account.t() | nil
  def account_by_id(account_id) do
    Repo.get(Account, account_id)
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

  defp build_min_date(type) do
    subtractor = build_min_date_subtractor(type)

    %{NaiveDateTime.utc_now() | microsecond: {0, 0}, second: 59, minute: 59, hour: 23}
    |> NaiveDateTime.add(-1 * @one_day_seconds * subtractor)
  end

  defp build_min_date_subtractor(type) do
    case type do
      :year ->
        365

      :month ->
        30

      :day ->
        1
    end
  end

  defp account_history_query(account_id) do
    from(h in AccountHistory, where: h.account_id == ^account_id, order_by: [desc: :inserted_at])
  end

  defp put_history_accumulators(history) do
    %{
      items: history,
      total_credit: sum_amount_for(history, "credit"),
      total_debit: sum_amount_for(history, "debit")
    }
  end

  defp sum_amount_for(list, key) do
    list
    |> Enum.filter(fn row -> row.type == key end)
    |> Enum.map(fn row -> row.amount end)
    |> Enum.sum()
  end
end
