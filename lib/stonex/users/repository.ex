defmodule Stonex.Users.Repository do
  @moduledoc """
  This module implement all interfaces needed
  to interact with user schema and database table
  """

  import Ecto.Query, warn: false

  alias Stonex.Repo
  alias Stonex.Users.User

  @doc """
  Receives a map with user data to be registered on the database

  ## Examples

    iex> {:ok, _} = Stonex.Users.Repository.signup(%{
    ...>   email: "duzzifelipe@gmail.com",
    ...>   first_name: "Felipe",
    ...>   last_name: "Duzzi",
    ...>   password: "sT0n3TEST",
    ...>   password_confirmation: "sT0n3TEST",
    ...>   registration_id: "397.257.568.86"
    ...> })
    ...> :ok
    :ok

    iex> {:ok, _} = Stonex.Users.Repository.signup(%{
    ...>   email: "duzzifelipe@gmail.com",
    ...>   first_name: "Felipe",
    ...>   password: "sT0n3TEST",
    ...>   password_confirmation: "sT0n3TEST",
    ...>   registration_id: "397.257.568.86"
    ...> })
    ...> :ok
    :ok
  """
  @spec signup(%{
          email: String.t(),
          first_name: String.t(),
          last_name: String.t() | nil,
          password: String.t(),
          password_confirmation: String.t(),
          registration_id: String.t()
        }) :: {:ok, %User{}} | {:error, String.t()}
  def signup(attrs) do
    %User{}
    |> User.signup_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Receives an email and raw password as arguments
  and searches on database for an user with that email.

  If an user is returned, check if raw password given
  matches encryption for the stored password.

  ## Examples
    iex> {:error, msg} = Stonex.Users.Repository.login(
    ...>   "duzzifelipe@gmail.com",
    ...>   "sT0n3TEST"
    ...> )
    ...> msg
    "invalid user and password"

    iex> {:ok, created_user} = Stonex.Users.Repository.signup(%{
    ...>   email: "duzzifelipe@gmail.com",
    ...>   first_name: "Felipe",
    ...>   last_name: "Duzzi",
    ...>   password: "sT0n3TEST",
    ...>   password_confirmation: "sT0n3TEST",
    ...>   registration_id: "397.257.568.86"
    ...> })
    ...> {:ok, user} = Stonex.Users.Repository.login(
    ...>   "duzzifelipe@gmail.com",
    ...>   "sT0n3TEST"
    ...> )
    ...> assert created_user.id == user.id
    true
  """
  @spec login(String.t(), String.t()) :: {:ok, User} | {:error, String.t()}
  def login(email, password) when is_binary(email) and is_binary(password) do
    with %User{} = user <- find_user_by_email(email),
         true <- User.password_valid?(user, password) do
      {:ok, user}
    else
      _ ->
        {:error, "invalid user and password"}
    end
  end

  def login(_, _) do
    {:error, "invalid user and password"}
  end

  @spec find_user_by_email(String.t()) :: %User{} | nil
  defp find_user_by_email(email) do
    from(u in User, where: u.email == ^email)
    |> Repo.one()
  end
end
