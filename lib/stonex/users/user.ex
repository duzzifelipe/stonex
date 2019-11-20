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

  def signup_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(
      attrs,
      [
        :first_name,
        :last_name,
        :registration_id,
        :email,
        :password,
        :password_confirmation
      ]
    )
    |> validate_required([
      :first_name,
      :registration_id,
      :email,
      :password,
      :password_confirmation
    ])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> hash_password()
    |> unique_constraint(:email)
    |> unique_constraint(:registration_id)
  end

  defp hash_password(%{valid?: false} = changeset), do: changeset

  defp hash_password(%{valid?: true} = changeset) do
    encrypted_password =
      changeset
      |> get_change(:password)
      |> Bcrypt.hash_pwd_salt()

    put_change(changeset, :encrypted_password, encrypted_password)
  end
end
