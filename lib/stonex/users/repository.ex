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
end
