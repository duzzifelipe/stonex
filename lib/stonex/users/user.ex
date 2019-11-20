defmodule Stonex.User do
  @moduledoc """
  This module holds the database structure
  and logic for bank users (clients).

  Operations made by an user and handled by user
  schema logic are registration and authentication
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:first_name, :string, null: false)
    field(:last_name, :string)
    field(:registration_id, :string, null: false)
    field(:email, :string, null: false)
    field(:encrypted_password, :string, null: false)

    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps()
  end
end
