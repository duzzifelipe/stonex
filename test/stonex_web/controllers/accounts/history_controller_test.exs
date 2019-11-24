defmodule Stonex.Accounts.HistoryControllerTest do
  use StonexWeb.ConnCase

  alias Stonex.{Accounts, Users}

  import Mock

  describe "account history controller index/2" do
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
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      %{"auth" => auth} =
        build_conn()
        |> post("/api/login", %{email: user.email, password: @pwd})
        |> json_response(200)

      response =
        build_conn()
        |> put_req_header("authorization", "Bearer #{auth}")
        |> get("/api/accounts/#{account.id}/history")
        |> json_response(200)

      assert !response["error"]

      assert response["history"] ==
               Jason.decode!(
                 Jason.encode!(Accounts.Repository.list_account_history(account, :all))
               )
    end

    test "with :day filter" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      account = Map.put(account, :user, user)

      today = NaiveDateTime.utc_now()
      one_day_ago = NaiveDateTime.add(today, -1 * 60 * 60 * 24)

      with_mocks [
        {NaiveDateTime, [], [utc_now: fn -> one_day_ago end, to_iso8601: fn _ -> today end]}
      ] do
        assert {:ok, _} = Accounts.Repository.withdraw_money(account, 60_000)
      end

      %{"auth" => auth} =
        build_conn()
        |> post("/api/login", %{email: user.email, password: @pwd})
        |> json_response(200)

      response =
        build_conn()
        |> put_req_header("authorization", "Bearer #{auth}")
        |> get("/api/accounts/#{account.id}/history?filter=day")
        |> json_response(200)

      assert !response["error"]

      assert response["history"] ==
               Jason.decode!(
                 Jason.encode!(Accounts.Repository.list_account_history(account, :day))
               )
    end

    test "with :month filter" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      account = Map.put(account, :user, user)

      today = NaiveDateTime.utc_now()
      one_month_ago = NaiveDateTime.add(today, -30 * 60 * 60 * 24)

      with_mocks [
        {NaiveDateTime, [], [utc_now: fn -> one_month_ago end, to_iso8601: fn _ -> today end]}
      ] do
        assert {:ok, _} = Accounts.Repository.withdraw_money(account, 60_000)
      end

      %{"auth" => auth} =
        build_conn()
        |> post("/api/login", %{email: user.email, password: @pwd})
        |> json_response(200)

      response =
        build_conn()
        |> put_req_header("authorization", "Bearer #{auth}")
        |> get("/api/accounts/#{account.id}/history?filter=month")
        |> json_response(200)

      assert !response["error"]

      assert response["history"] ==
               Jason.decode!(
                 Jason.encode!(Accounts.Repository.list_account_history(account, :month))
               )
    end

    test "with :year filter" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      account = Map.put(account, :user, user)

      today = NaiveDateTime.utc_now()
      one_year_ago = NaiveDateTime.add(today, -365 * 60 * 60 * 24)

      with_mocks [
        {NaiveDateTime, [], [utc_now: fn -> one_year_ago end, to_iso8601: fn _ -> today end]}
      ] do
        assert {:ok, _} = Accounts.Repository.withdraw_money(account, 60_000)
      end

      %{"auth" => auth} =
        build_conn()
        |> post("/api/login", %{email: user.email, password: @pwd})
        |> json_response(200)

      response =
        build_conn()
        |> put_req_header("authorization", "Bearer #{auth}")
        |> get("/api/accounts/#{account.id}/history?filter=year")
        |> json_response(200)

      assert !response["error"]

      assert response["history"] ==
               Jason.decode!(
                 Jason.encode!(Accounts.Repository.list_account_history(account, :year))
               )
    end

    test "no user" do
      assert {:ok, user} = Users.Repository.signup(@valid_user_parameters)
      assert {:ok, account} = Accounts.Repository.create_account(user, 1)

      response =
        build_conn()
        |> get("/api/accounts/#{account.id}/history")
        |> json_response(401)

      assert response == %{"error" => "unauthenticated"}
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
        |> get("/api/accounts/#{account.id}/history")
        |> json_response(200)

      assert response == %{"error" => "account not found"}
    end
  end
end
