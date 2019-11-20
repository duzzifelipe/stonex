defmodule Stonex.AccountTest do
  use Stonex.DataCase

  alias Stonex.Accounts.Account

  describe "accounts" do
    @valid_parameters %{
      user_id: Faker.Util.pick(0..100),
      agency: Faker.Util.pick(1000..99_999),
      number: Faker.Util.pick(1000..99_999),
      balance: Faker.Util.pick(0..9_999_999)
    }

    test "create_changeset/2 with valid parameters" do
      changeset = Account.create_changeset(%Account{}, @valid_parameters)
      assert changeset.valid?
    end

    test "create_changeset/2 without user_id" do
      params = Map.delete(@valid_parameters, :user_id)
      changeset = Account.create_changeset(%Account{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:user_id]
      error = Keyword.fetch!(changeset.errors, :user_id)
      assert elem(error, 0) == "can't be blank"
    end

    test "create_changeset/2 without number" do
      params = Map.delete(@valid_parameters, :number)
      changeset = Account.create_changeset(%Account{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:number]
      error = Keyword.fetch!(changeset.errors, :number)
      assert elem(error, 0) == "can't be blank"
    end

    test "create_changeset/2 without agency" do
      params = Map.delete(@valid_parameters, :agency)
      changeset = Account.create_changeset(%Account{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:agency]
      error = Keyword.fetch!(changeset.errors, :agency)
      assert elem(error, 0) == "can't be blank"
    end

    test "create_changeset/2 without balance" do
      params = Map.delete(@valid_parameters, :balance)
      changeset = Account.create_changeset(%Account{}, params)

      assert !changeset.valid?
      assert Keyword.keys(changeset.errors) == [:balance]
      error = Keyword.fetch!(changeset.errors, :balance)
      assert elem(error, 0) == "can't be blank"
    end
  end
end
