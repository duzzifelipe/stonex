defmodule Stonex.Users.Guardian do
  @moduledoc """
  Encodes and decods user object to authenticate
  users using JWT
  """

  use Guardian, otp_app: :stonex

  alias Stonex.Users.{Repository, User}

  def subject_for_token(%User{} = resource, _) do
    sub = to_string(resource.email)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    email = claims["sub"]

    case Repository.find_user_by_email(email) do
      %User{} = resource ->
        {:ok, resource}

      _ ->
        {:error, "not found"}
    end
  end
end
