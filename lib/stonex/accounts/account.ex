defmodule Stonex.Accounts.Account do
  @moduledoc """
  This module holds the database structure
  and logic for bank accounts.

  Operations on a account are their creation,
  associated to an existent user and balance
  update (called by withdraws and transfers)

  Account balance is represented by integers,
  using two digits for decimals:
  123.45 -> 12345
  123.00 -> 12300
  This requires users to provide correct values.
  """

  alias Stonex.Users.User
  alias Stonex.Accounts.AccountHistory

  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field(:agency, :integer, null: false)
    field(:number, :integer, null: false)
    field(:balance, :integer, null: false)

    belongs_to(:user, User)
    has_many(:other, AccountHistory, on_delete: :delete_all)

    timestamps()
  end

  @doc """
  Receives a map containing number and account
  digits alongside an user_id.

  ## Examples

      iex> changeset = Stonex.Accounts.Account.create_changeset(
      ...>   %Stonex.Accounts.Account{},
      ...>   %{
      ...>      user_id: 1,
      ...>      agency: 1,
      ...>      number: 321,
      ...>      balance: 200000
      ...>   }
      ...> )
      ...> changeset.valid?
      true
  """
  def create_changeset(%__MODULE__{} = account, attrs) do
    account
    |> cast(attrs, [:agency, :number, :user_id, :balance])
    |> validate_required([:agency, :number, :user_id, :balance])
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Receives an account struct and an amount
  value to be DEBITED from the account

      iex> changeset = Stonex.Accounts.Account.update_balance_changeset(
      ...>   %Stonex.Accounts.Account{balance: 1000},
      ...>   :debit,
      ...>   999
      ...> )
      ...> changeset.valid?
      true

      iex> changeset = Stonex.Accounts.Account.update_balance_changeset(
      ...>   %Stonex.Accounts.Account{balance: 1000},
      ...>   :debit,
      ...>   1001
      ...> )
      ...> changeset.valid?
      false
  """
  def update_balance_changeset(%__MODULE__{} = account, :debit, amount) do
    changeset = cast(account, %{}, [])

    if valid_transaction_amount?(amount) && account.balance >= amount do
      update_balance_changeset(changeset, account.balance - amount)
    else
      add_error(changeset, :balance, "provided value is not valid")
    end
  end

  @doc """
  Receives an account struct and an amount
  value to be CREDITED from the account

      iex> changeset = Stonex.Accounts.Account.update_balance_changeset(
      ...>   %Stonex.Accounts.Account{balance: 1000},
      ...>   :credit,
      ...>   999
      ...> )
      ...> changeset.valid?
      true
  """
  def update_balance_changeset(%__MODULE__{} = account, :credit, amount) do
    changeset = cast(account, %{}, [])

    if valid_transaction_amount?(amount) do
      update_balance_changeset(changeset, account.balance + amount)
    else
      add_error(changeset, :balance, "provided value is not valid")
    end
  end

  defp valid_transaction_amount?(value) when is_integer(value) and value > 0, do: true

  defp valid_transaction_amount?(_), do: false

  defp update_balance_changeset(changeset, new_balance) do
    put_change(changeset, :balance, new_balance)
  end
end
