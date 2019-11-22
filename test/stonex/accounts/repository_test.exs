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

      # validate transaction history
      transactions = Accounts.Repository.list_account_history(account, :all)
      assert Enum.count(transactions) == 1

      transaction = Enum.at(transactions, 0)
      assert transaction.account_id == account.id
      assert transaction.type == "credit"
      assert transaction.amount == 100_000
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

      # the account has a first transaction from setup
      # so this one on the test is the second one
      transactions = Accounts.Repository.list_account_history(account_updated, :all)

      assert Enum.count(transactions) == 2

      transaction = Enum.at(transactions, 1)
      assert transaction.account_id == account.id
      assert transaction.type == "debit"
      assert transaction.amount == 90_000
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

    test "transfer_money/3 with valid parameters" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 1)

      assert {:ok, {new_1, new_2}} =
               Accounts.Repository.transfer_money(account_1, account_2, 90_000)

      assert new_1.balance == 10_000
      assert new_2.balance == 190_000

      # both accounts have the first credit
      # but this checks for the second one
      transactions_1 = Accounts.Repository.list_account_history(account_1, :all)
      transactions_2 = Accounts.Repository.list_account_history(account_2, :all)

      assert Enum.count(transactions_1) == 2
      assert Enum.count(transactions_2) == 2

      transaction_1 = Enum.at(transactions_1, 1)
      assert transaction_1.account_id == account_1.id
      assert transaction_1.type == "debit"
      assert transaction_1.amount == 90_000

      transaction_2 = Enum.at(transactions_2, 1)
      assert transaction_2.account_id == account_2.id
      assert transaction_2.type == "credit"
      assert transaction_2.amount == 90_000
    end

    test "transfer_money/3 with not enough money on debit account" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 1)

      assert {:error, {chnst_1, chnst_2}} =
               Accounts.Repository.transfer_money(account_1, account_2, 120_000)

      assert chnst_1 == [balance: {"provided value is not valid", []}]
      assert chnst_2 == []
    end

    test "transfer_money/3 with invalid amount" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 1)

      assert {:error, {chnst_1, chnst_2}} =
               Accounts.Repository.transfer_money(account_1, account_2, -20_000)

      assert chnst_1 == [balance: {"provided value is not valid", []}]
      assert chnst_2 == [balance: {"provided value is not valid", []}]
    end

    test "transfer_money/3 with nonexistent debit account" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 1)

      # remove debit account
      Repo.delete(account_1)

      assert_raise(Ecto.StaleEntryError, fn ->
        Accounts.Repository.transfer_money(account_1, account_2, 90_000)
      end)

      # check account 2 balance
      new_2 = Repo.get!(Accounts.Account, account_2.id)
      assert new_2.balance == 100_000
    end

    test "transfer_money/3 with nonexistent credit account" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 1)

      # remove credit account
      Repo.delete(account_2)

      assert_raise(Ecto.StaleEntryError, fn ->
        Accounts.Repository.transfer_money(account_1, account_2, 90_000)
      end)

      # check account 1 balance
      new_1 = Repo.get!(Accounts.Account, account_1.id)
      assert new_1.balance == 100_000
    end

    test "list_account_history/2 :all" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      assert {:ok, account_updated} = Accounts.Repository.withdraw_money(account, 60_000)
      assert {:error, _} = Accounts.Repository.withdraw_money(account_updated, 41_000)

      transactions = Accounts.Repository.list_account_history(account, :all)

      assert Enum.count(transactions) == 2

      transaction_1 = Enum.at(transactions, 0)
      assert transaction_1.account_id == account.id
      assert transaction_1.type == "credit"
      assert transaction_1.amount == 100_000

      transaction_2 = Enum.at(transactions, 1)
      assert transaction_2.account_id == account.id
      assert transaction_2.type == "debit"
      assert transaction_2.amount == 60_000
    end

    test "list_account_history/2 invalid filter" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      assert_raise(FunctionClauseError, fn ->
        Accounts.Repository.list_account_history(account, "any")
      end)
    end
  end
end
