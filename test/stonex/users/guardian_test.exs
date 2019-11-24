defmodule Stonex.Users.GuardianTest do
  use Stonex.DataCase

  alias Stonex.Users.{Guardian, Repository}

  doctest Stonex.Users.Guardian

  @pwd Faker.String.base64(8)

  @valid_parameters %{
    first_name: Faker.Name.first_name(),
    last_name: Faker.Name.last_name(),
    registration_id: to_string(CPF.generate()),
    email: Faker.Internet.email(),
    password: @pwd,
    password_confirmation: @pwd
  }

  describe "users guardian subject_for_token/2" do
    test "with valid user" do
      assert {:ok, user} = Repository.signup(@valid_parameters)
      assert {:ok, sub} = Guardian.subject_for_token(user, nil)
      assert sub == user.email
    end
  end

  describe "users guardian resource_from_claims/claims" do
    test "with valid user param" do
      assert {:ok, user} = Repository.signup(@valid_parameters)

      claims = %{"sub" => user.email}

      assert {:ok, resource} = Guardian.resource_from_claims(claims)
      assert resource.id == user.id
      assert resource.email == user.email
    end

    test "with valid not found user param" do
      claims = %{"sub" => Faker.Internet.email()}

      assert {:error, "not found"} = Guardian.resource_from_claims(claims)
    end
  end
end
