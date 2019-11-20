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

  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field(:agency, :integer, null: false)
    field(:number, :integer, null: false)
    field(:balance, :integer, null: false)

    belongs_to(:user, User)

    timestamps()
  end
end
