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

  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field(:agency, :integer, null: false)
    field(:number, :integer, null: false)
    field(:balance, :integer, null: false)

    belongs_to(:user, User)

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
  Verifies if an account has sufficient
  balance to allow debiting a value

  ## Examples

      iex> Stonex.Accounts.Account.can_debit?(
      ...>   %Stonex.Accounts.Account{balance: 1000},
      ...>   999
      ...> )
      true

      iex> Stonex.Accounts.Account.can_debit?(
      ...>   %Stonex.Accounts.Account{balance: 1000},
      ...>   1001
      ...> )
      false
  """
  @spec can_debit?(Stonex.Accounts.Account.t(), number) :: boolean
  def can_debit?(%__MODULE__{} = account, debit_value) when is_integer(debit_value) and debit_value > 0 do
    account.balance >= debit_value
  end

  def can_debit?(_, _), do: false
end
