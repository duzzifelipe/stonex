defmodule Stonex.Accounts.TransactionControllerTest do
  use StonexWeb.ConnCase

  alias Stonex.{Accounts, Users}

  @pwd Faker.String.base64(8)

  @valid_user_parameters %{
    first_name: Faker.Name.first_name(),
    last_name: Faker.Name.last_name(),
    registration_id: to_string(CPF.generate()),
    email: Faker.Internet.email(),
    password: @pwd,
    password_confirmation: @pwd
  }

  describe "account transaction controller withdraw/2" do
    test "with valid data" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      amount = 15_000

      %{"auth" => auth} =
        build_conn()
        |> post("/api/login", %{email: user.email, password: @pwd})
        |> json_response(200)

      response =
        build_conn()
        |> put_req_header("authorization", "Bearer #{auth}")
        |> post("/api/accounts/#{account.id}/transactions/withdraw", %{"amount" => amount})
        |> json_response(200)

      assert !response["error"]
      assert response["account"]["balance"] == account.balance - amount
    end

    test "no user" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      response =
        build_conn()
        |> post("/api/accounts/#{account.id}/transactions/withdraw", %{"amount" => 15_000})
        |> json_response(401)

      assert response == %{"error" => "unauthenticated"}
    end

    test "with invalid amount format" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      %{"auth" => auth} =
        build_conn()
        |> post("/api/login", %{email: user.email, password: @pwd})
        |> json_response(200)

      response =
        build_conn()
        |> put_req_header("authorization", "Bearer #{auth}")
        |> post("/api/accounts/#{account.id}/transactions/withdraw", %{"amount" => 150.00})
        |> json_response(200)

      assert %{"account" => nil, "error" => "invalid amount to withdraw"} = response
    end

    test "without amount parameter" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      %{"auth" => auth} =
        build_conn()
        |> post("/api/login", %{email: user.email, password: @pwd})
        |> json_response(200)

      response =
        build_conn()
        |> put_req_header("authorization", "Bearer #{auth}")
        |> post("/api/accounts/#{account.id}/transactions/withdraw", %{})
        |> json_response(200)

      assert %{"account" => nil, "error" => "invalid amount to withdraw"} = response
    end

    test "user does not own account" do
      # creates an account for user_1
      # and accesses the api with user_2
      params =
        @valid_user_parameters
        |> Map.put(:email, Faker.Internet.email())
        |> Map.put(:registration_id, to_string(CPF.generate()))

      assert {:ok, user_1} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, user_2} = Users.Repository.signup(params)
      assert {:ok, account} = Accounts.Repository.create_account(user_1, 1)

      %{"auth" => auth} =
        build_conn()
        |> post("/api/login", %{email: user_2.email, password: @pwd})
        |> json_response(200)

      response =
        build_conn()
        |> put_req_header("authorization", "Bearer #{auth}")
        |> post("/api/accounts/#{account.id}/transactions/withdraw", %{"amount" => 15_000})
        |> json_response(200)

      assert response == %{"error" => "account not found"}
    end
  end
end
