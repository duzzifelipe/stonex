defmodule Stonex.Users.User do
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

  @doc """
  Receives a argument containing a raw struct for current module
  and a map of values with fields to be inserted.

  ## Examples

      iex> changeset = Stonex.Users.User.signup_changeset(%Stonex.Users.User{}, %{
      ...>   first_name: "Felipe",
      ...>   last_name: "Duzzi",
      ...>   registration_id: "397.257.568-86",
      ...>   email: "duzzifelipe@gmail.com",
      ...>   password: "abcdefg",
      ...>   password_confirmation: "abcdefg"
      ...> })
      ...> changeset.valid?
      true
  """
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

  @doc """
  Receives an user struct and a raw password string.
  It checks if given password matches encrypted_password
  from user struct

  ## Examples

      iex> Stonex.Users.User.password_valid?(
      ...>   %Stonex.Users.User{encrypted_password: ""},
      ...>   "abcdefg"
      ...> )
      false

      iex> enc = Bcrypt.hash_pwd_salt("abcdefg")
      ...> Stonex.Users.User.password_valid?(
      ...>   %Stonex.Users.User{encrypted_password: enc},
      ...>   "abcdefg"
      ...> )
      true
  """
  @spec password_valid?(Stonex.Users.User.t(), String.t()) :: boolean
  def password_valid?(%__MODULE__{} = user, password) do
    case Bcrypt.check_pass(user, password) do
      {:ok, _user} -> true
      {:error, _message} -> false
    end
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
