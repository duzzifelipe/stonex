defmodule Stonex.Accounts.RepositoryTest do
  use Stonex.DataCase
  alias Stonex.Users
  alias Stonex.Accounts

  doctest Stonex.Accounts.Repository

  describe "accounts repository" do
    @pwd Faker.String.base64(8)

    @valid_user_parameters %{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      registration_id: to_string(CPF.generate()),
      email: Faker.Internet.email(),
      password: @pwd,
      password_confirmation: @pwd
    }

    test "create_account/2 with valid data" do
      agency = Faker.Util.pick(0..100)

      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, agency)

      assert account.agency == agency
      assert account.number == 1
      assert account.user_id == user.id
      assert account.balance == 100_000
    end

    test "create_account/2 with new agency" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 2)

      # creating on different agencies, account number can be equal
      assert account_1.agency == 1
      assert account_1.number == 1

      assert account_2.agency == 2
      assert account_2.number == 1
    end

    test "create_account/2 with same agency" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 1)

      # creating same agency, account number won't be equal
      assert account_1.agency == 1
      assert account_1.number == 1

      assert account_2.agency == 1
      assert account_2.number == 2
    end

    test "create_account/2 with nonexistent user" do
      user = %Users.User{id: 1}
      {:error, changeset} = Accounts.Repository.create_account(user, 1)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:user_id]
      error = Keyword.fetch!(changeset.errors, :user_id)
      assert elem(error, 0) == "does not exist"
    end

    test "withdraw_money/2 with valid parameters" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      assert {:ok, account_updated} = Accounts.Repository.withdraw_money(account, 90_000)
      assert account_updated.balance == 10_000
    end

    test "withdraw_money/2 with not enough money" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      assert {:error, errors} = Accounts.Repository.withdraw_money(account, 200_000)
      assert Keyword.keys(errors) == [:balance]
      error = Keyword.fetch!(errors, :balance)
      assert elem(error, 0) == "provided value is not valid"
    end

    test "withdraw_money/2 with nonexistent account" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      new_account = %{account | id: account.id + 1}

      assert_raise(Ecto.StaleEntryError, fn ->
        Accounts.Repository.withdraw_money(new_account, 90_000)
      end)
    end
  end
end
