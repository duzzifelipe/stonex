defmodule Stonex.UserTest do
  use Stonex.DataCase

  alias Stonex.User

  describe "users" do
    @pwd Faker.String.base64(8)

    @valid_parameters %{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      registration_id: Faker.Code.issn(),
      email: Faker.Internet.email(),
      password: @pwd,
      password_confirmation: @pwd
    }

    test "signup_changeset/2 with valid parameters" do
      changeset = User.signup_changeset(%User{}, @valid_parameters)
      assert changeset.valid?
    end

    test "signup_changeset/2 with no arguments" do
      changeset = User.signup_changeset(%User{}, %{})
      assert !changeset.valid?
    end

    test "signup_changeset/2 without first name" do
      params = Map.delete(@valid_parameters, :first_name)
      changeset = User.signup_changeset(%User{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:first_name]
      error = Keyword.fetch!(changeset.errors, :first_name)
      assert elem(error, 0) == "can't be blank"
    end

    test "signup_changeset/2 without registration_id" do
      params = Map.delete(@valid_parameters, :registration_id)
      changeset = User.signup_changeset(%User{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:registration_id]
      error = Keyword.fetch!(changeset.errors, :registration_id)
      assert elem(error, 0) == "can't be blank"
    end

    test "signup_changeset/2 without email" do
      params = Map.delete(@valid_parameters, :email)
      changeset = User.signup_changeset(%User{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:email]
      error = Keyword.fetch!(changeset.errors, :email)
      assert elem(error, 0) == "can't be blank"
    end

    test "signup_changeset/2 with wrong email format" do
      params = Map.put(@valid_parameters, :email, Faker.String.base64(15))
      changeset = User.signup_changeset(%User{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:email]
      error = Keyword.fetch!(changeset.errors, :email)
      assert elem(error, 0) == "has invalid format"
    end

    test "signup_changeset/2 without password" do
      params = Map.delete(@valid_parameters, :password)
      changeset = User.signup_changeset(%User{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:password_confirmation, :password]
      error = Keyword.fetch!(changeset.errors, :password)
      assert elem(error, 0) == "can't be blank"
    end

    test "signup_changeset/2 without password confirmation" do
      params = Map.delete(@valid_parameters, :password_confirmation)
      changeset = User.signup_changeset(%User{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:password_confirmation]
      error = Keyword.fetch!(changeset.errors, :password_confirmation)
      assert elem(error, 0) == "can't be blank"
    end

    test "signup_changeset/2 with small password" do
      pwd = Faker.String.base64(4)

      params =
        @valid_parameters
        |> Map.put(:password, pwd)
        |> Map.put(:password_confirmation, pwd)

      changeset = User.signup_changeset(%User{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:password]
      error = Keyword.fetch!(changeset.errors, :password)

      assert elem(error, 0) == "should be at least %{count} character(s)"
      assert Keyword.fetch!(elem(error, 1), :count) == 6
    end

    test "signup_changeset/2 with password not matching" do
      params = Map.put(@valid_parameters, :password_confirmation, Faker.String.base64(6))
      changeset = User.signup_changeset(%User{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:password_confirmation]
      error = Keyword.fetch!(changeset.errors, :password_confirmation)
      assert elem(error, 0) == "does not match confirmation"
    end
  end
end
