defmodule Stonex.AccountHistoryTest do
  use Stonex.DataCase

  alias Stonex.Accounts.AccountHistory

  doctest Stonex.Accounts.AccountHistory

  describe "account_histories" do
    @valid_parameters %{
      account_id: Faker.Util.pick(0..999),
      type: "credit",
      amount: Faker.Util.pick(1000..99_999)
    }

    test "create_changeset/2 with valid credit parameters" do
      changeset = AccountHistory.create_changeset(%AccountHistory{}, @valid_parameters)
      assert changeset.valid?
    end

    test "create_changeset/2 with valid debit parameters" do
      parameters = Map.put(@valid_parameters, :type, "debit")
      changeset = AccountHistory.create_changeset(%AccountHistory{}, parameters)
      assert changeset.valid?
    end

    test "create_changeset/2 with negative amount" do
      parameters = Map.put(@valid_parameters, :amount, Faker.Util.pick(-99_999..-1000))
      changeset = AccountHistory.create_changeset(%AccountHistory{}, parameters)
      assert !changeset.valid?
    end

    test "create_changeset/2 with invalid amount type" do
      parameters = Map.put(@valid_parameters, :amount, Faker.String.base64(4))
      changeset = AccountHistory.create_changeset(%AccountHistory{}, parameters)
      assert !changeset.valid?
    end

    test "create_changeset/2 with invalid type" do
      parameters = Map.put(@valid_parameters, :type, "loan")
      changeset = AccountHistory.create_changeset(%AccountHistory{}, parameters)
      assert !changeset.valid?
    end

    test "create_changeset/2 without type" do
      parameters = Map.delete(@valid_parameters, :type)
      changeset = AccountHistory.create_changeset(%AccountHistory{}, parameters)
      assert !changeset.valid?
    end

    test "create_changeset/2 without amount" do
      parameters = Map.delete(@valid_parameters, :amount)
      changeset = AccountHistory.create_changeset(%AccountHistory{}, parameters)
      assert !changeset.valid?
    end

    test "create_changeset/2 without account_id" do
      parameters = Map.delete(@valid_parameters, :account_id)
      changeset = AccountHistory.create_changeset(%AccountHistory{}, parameters)
      assert !changeset.valid?
    end
  end
end
