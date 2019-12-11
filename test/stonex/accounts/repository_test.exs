defmodule Stonex.Accounts.RepositoryTest do
  use Stonex.DataCase
  alias Stonex.Users
  alias Stonex.Accounts

  doctest Stonex.Accounts.Repository

  import Mock

  describe "accounts repository create_account/2" do
    @pwd Faker.String.base64(8)

    @valid_user_parameters %{
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      registration_id: to_string(CPF.generate()),
      email: Faker.Internet.email(),
      password: @pwd,
      password_confirmation: @pwd
    }

    test "with valid data" do
      agency = Faker.Util.pick(0..100)

      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, agency)

      assert account.agency == agency
      assert account.number == 1
      assert account.user_id == user.id
      assert account.balance == 100_000

      # validate transaction history
      transactions = Accounts.Repository.list_account_history(account, :all)
      assert Enum.count(transactions.items) == 1

      assert transactions.total_credit == 100_000
      assert transactions.total_debit == 0

      transaction = Enum.at(transactions.items, 0)
      assert transaction.account_id == account.id
      assert transaction.type == "credit"
      assert transaction.amount == 100_000
    end

    test "with new agency" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 2)

      # creating on different agencies, account number can be equal
      assert account_1.agency == 1
      assert account_1.number == 1

      assert account_2.agency == 2
      assert account_2.number == 1
    end

    test "with same agency" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 1)
      assert {:ok, _account_3} = Accounts.Repository.create_account(user, 1)

      # creating same agency, account number won't be equal
      assert account_1.agency == 1
      assert account_1.number == 1

      assert account_2.agency == 1
      assert account_2.number == 2
    end

    test "with nonexistent user" do
      user = %Users.User{id: 1}
      {:error, changeset} = Accounts.Repository.create_account(user, 1)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:user_id]
      error = Keyword.fetch!(changeset.errors, :user_id)
      assert elem(error, 0) == "does not exist"
    end
  end

  describe "accounts repository withdraw_money/2" do
    test "with valid parameters" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      account = Map.put(account, :user, user)
      assert {:ok, account_updated} = Accounts.Repository.withdraw_money(account, 90_000)
      assert account_updated.balance == 10_000

      # the account has a first transaction from setup
      # so this one on the test is the second one
      transactions = Accounts.Repository.list_account_history(account_updated, :all)

      assert Enum.count(transactions.items) == 2

      assert transactions.total_credit == 100_000
      assert transactions.total_debit == 90_000

      transaction = Enum.at(transactions.items, 1)
      assert transaction.account_id == account.id
      assert transaction.type == "debit"
      assert transaction.amount == 90_000
    end

    test "with not enough money" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      account = Map.put(account, :user, user)
      assert {:error, changeset} = Accounts.Repository.withdraw_money(account, 200_000)
      assert Keyword.keys(changeset.errors) == [:balance]
      error = Keyword.fetch!(changeset.errors, :balance)
      assert elem(error, 0) == "provided value is not valid"
    end

    test "with nonexistent account" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      new_account = %{account | id: account.id + 1, user: user}

      assert_raise(Ecto.StaleEntryError, fn ->
        Accounts.Repository.withdraw_money(new_account, 90_000)
      end)
    end
  end

  describe "accounts repository transfer_money/3" do
    test "with valid parameters" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 1)

      account_1 = Map.put(account_1, :user, user)

      assert {:ok, {new_1, new_2}} =
               Accounts.Repository.transfer_money(account_1, account_2, 90_000)

      assert new_1.balance == 10_000
      assert new_2.balance == 190_000

      # both accounts have the first credit
      # but this checks for the second one
      transactions_1 = Accounts.Repository.list_account_history(account_1, :all)
      transactions_2 = Accounts.Repository.list_account_history(account_2, :all)

      assert Enum.count(transactions_1.items) == 2
      assert Enum.count(transactions_2.items) == 2

      assert transactions_1.total_credit == 100_000
      assert transactions_1.total_debit == 90_000

      assert transactions_2.total_credit == 190_000
      assert transactions_2.total_debit == 0

      transaction_1 = Enum.at(transactions_1.items, 1)
      assert transaction_1.account_id == account_1.id
      assert transaction_1.type == "debit"
      assert transaction_1.amount == 90_000

      transaction_2 = Enum.at(transactions_2.items, 1)
      assert transaction_2.account_id == account_2.id
      assert transaction_2.type == "credit"
      assert transaction_2.amount == 90_000
    end

    test "with not enough money on debit account" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 1)

      account_1 = Map.put(account_1, :user, user)

      assert {:error, {chnst_1, chnst_2}} =
               Accounts.Repository.transfer_money(account_1, account_2, 120_000)

      assert chnst_1.errors == [balance: {"provided value is not valid", []}]
      assert chnst_2.errors == []
    end

    test "with invalid amount" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)

      assert {:ok, account_1} = Accounts.Repository.create_account(user, 1)
      assert {:ok, account_2} = Accounts.Repository.create_account(user, 1)

      account_1 = Map.put(account_1, :user, user)

      assert {:error, {chnst_1, chnst_2}} =
               Accounts.Repository.transfer_money(account_1, account_2, -20_000)

      assert chnst_1.errors == [balance: {"provided value is not valid", []}]
      assert chnst_2.errors == [balance: {"provided value is not valid", []}]
    end

    test "with nonexistent debit account" do
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

    test "with nonexistent credit account" do
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

    test "with same debit and credit account" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)
      account = Map.put(account, :user, user)

      assert {:error, {msg_1, msg_2}} =
               Accounts.Repository.transfer_money(account, account, 90_000)

      assert msg_1 == "accounts must be different"
      assert msg_2 == "accounts must be different"
    end
  end

  describe "accounts repository list_account_history/2" do
    test ":all" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      account = Map.put(account, :user, user)
      assert {:ok, account_updated} = Accounts.Repository.withdraw_money(account, 60_000)
      assert {:error, _} = Accounts.Repository.withdraw_money(account_updated, 41_000)

      transactions = Accounts.Repository.list_account_history(account, :all)

      assert Enum.count(transactions.items) == 2

      assert transactions.total_credit == 100_000
      assert transactions.total_debit == 60_000

      transaction_1 = Enum.at(transactions.items, 0)
      assert transaction_1.account_id == account.id
      assert transaction_1.type == "credit"
      assert transaction_1.amount == 100_000

      transaction_2 = Enum.at(transactions.items, 1)
      assert transaction_2.account_id == account.id
      assert transaction_2.type == "debit"
      assert transaction_2.amount == 60_000
    end

    test ":day" do
      today = NaiveDateTime.utc_now()
      one_day_ago = NaiveDateTime.add(today, -1 * 60 * 60 * 24)

      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      account = Map.put(account, :user, user)

      # this is a little bit strange:
      # since account was created without mock (today)
      # the transaction is made with mock (two days ago)
      # but since there is no validation for it
      # it helps testing the list_account_history's filter
      with_mocks [
        {NaiveDateTime, [], [utc_now: fn -> one_day_ago end, to_iso8601: fn _ -> today end]}
      ] do
        assert {:ok, _} = Accounts.Repository.withdraw_money(account, 60_000)
      end

      transactions_1 = Accounts.Repository.list_account_history(account, :all)
      transactions_2 = Accounts.Repository.list_account_history(account, :day)

      assert Enum.count(transactions_1.items) == 2
      assert Enum.count(transactions_2.items) == 1
    end

    test ":month" do
      today = NaiveDateTime.utc_now()
      one_month_ago = NaiveDateTime.add(today, -1 * 60 * 60 * 24 * 30)

      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      account = Map.put(account, :user, user)

      with_mocks [
        {NaiveDateTime, [], [utc_now: fn -> one_month_ago end, to_iso8601: fn _ -> today end]}
      ] do
        assert {:ok, _} = Accounts.Repository.withdraw_money(account, 60_000)
      end

      transactions_1 = Accounts.Repository.list_account_history(account, :all)
      transactions_2 = Accounts.Repository.list_account_history(account, :month)

      assert Enum.count(transactions_1.items) == 2
      assert Enum.count(transactions_2.items) == 1
    end

    test ":year" do
      today = NaiveDateTime.utc_now()
      one_year_ago = NaiveDateTime.add(today, -1 * 60 * 60 * 24 * 365)

      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      account = Map.put(account, :user, user)

      with_mocks [
        {NaiveDateTime, [], [utc_now: fn -> one_year_ago end, to_iso8601: fn _ -> today end]}
      ] do
        assert {:ok, _} = Accounts.Repository.withdraw_money(account, 60_000)
      end

      transactions_1 = Accounts.Repository.list_account_history(account, :all)
      transactions_2 = Accounts.Repository.list_account_history(account, :year)

      assert Enum.count(transactions_1.items) == 2
      assert Enum.count(transactions_2.items) == 1
    end

    test "invalid filter" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      assert_raise(FunctionClauseError, fn ->
        Accounts.Repository.list_account_history(account, "any")
      end)
    end
  end

  describe "accounts repository account_by_user/2" do
    test "with existent user and account" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      assert %Accounts.Account{} = acc = Accounts.Repository.account_by_user(user, account.id)

      assert account.id == acc.id
      assert account.user_id == user.id
    end

    test "with unexistent user" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      params =
        @valid_user_parameters
        |> Map.put(:email, Faker.Internet.email())
        |> Map.put(:registration_id, to_string(CPF.generate()))

      assert {:ok, user_2} = Users.Repository.signup(params)
      assert nil == Accounts.Repository.account_by_user(user_2, account.id)
    end

    test "with unexistent account" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert nil == Accounts.Repository.account_by_user(user, 1)
    end
  end

  describe "accounts repository account_by_id/2" do
    test "with existent account" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)
      assert %Accounts.Account{} = acc = Accounts.Repository.account_by_id(account.id)

      assert account.id == acc.id
      assert account.user_id == user.id
    end

    test "with unexistent account" do
      assert nil == Accounts.Repository.account_by_id(1)
    end
  end
end
