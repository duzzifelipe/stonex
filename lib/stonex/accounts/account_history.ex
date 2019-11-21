defmodule Stonex.Accounts.AccountHistory do
  @moduledoc """
  This module holds the database structure
  and logic for bank account operation history.

  It holds information related to an account and
  register the amount that was credited or
  debited, always as positive values.
  """

  alias Stonex.Accounts.Account

  use Ecto.Schema
  import Ecto.Changeset

  schema "account_histories" do
    field(:type, :string, null: false)
    field(:amount, :integer, null: false)

    belongs_to :account, Account

    timestamps()
  end
end
