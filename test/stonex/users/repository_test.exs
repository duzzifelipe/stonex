defmodule Stonex.Users.RepositoryTest do
  use Stonex.DataCase
  alias Stonex.Users.{Repository, User}

  doctest Stonex.Users.Repository

  describe "users repository" do
    @pwd Faker.String.base64(8)

    @valid_parameters %{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      registration_id: Faker.Code.issn(),
      email: Faker.Internet.email(),
      password: @pwd,
      password_confirmation: @pwd
    }

    test "signup/1 with valid data" do
      assert {:ok, user} = Repository.signup(@valid_parameters)

      assert user.first_name == @valid_parameters.first_name
      assert user.last_name == @valid_parameters.last_name
      assert user.registration_id == @valid_parameters.registration_id
      assert user.email == @valid_parameters.email
      assert User.password_valid?(user, @pwd)
    end

    test "signup/1 with duplicated email" do
      assert {:ok, user} = Repository.signup(@valid_parameters)

      repeated_email_attrs = Map.put(@valid_parameters, :registration_id, Faker.Code.issn())
      assert {:error, changeset} = Repository.signup(repeated_email_attrs)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:email]

      error = Keyword.fetch!(changeset.errors, :email)
      assert elem(error, 0) == "has already been taken"
    end

    test "signup/1 with duplicated registration_id" do
      assert {:ok, user} = Repository.signup(@valid_parameters)

      repeated_reg_attrs = Map.put(@valid_parameters, :email, Faker.Internet.email())
      assert {:error, changeset} = Repository.signup(repeated_reg_attrs)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:registration_id]

      error = Keyword.fetch!(changeset.errors, :registration_id)
      assert elem(error, 0) == "has already been taken"
    end
  end
end
