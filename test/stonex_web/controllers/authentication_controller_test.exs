defmodule Stonex.AuthenticationControllerTest do
  use StonexWeb.ConnCase

  @email Faker.Internet.email()
  @pwd Faker.String.base64(8)

  @valid_user_data [
    first_name: Faker.Name.first_name(),
    last_name: Faker.Name.last_name(),
    registration_id: to_string(CPF.generate()),
    email: @email,
    password: @pwd,
    password_confirmation: @pwd,
    agency: Faker.Util.pick(1..99)
  ]

  describe "authentication_controller POST /signup" do
    test "with valid data" do
      response =
        build_conn()
        |> post("/api/signup", @valid_user_data)
        |> json_response(200)

      assert %{
               "error" => nil,
               "user" => %{
                 "email" => @email,
                 "first_name" => _,
                 "id" => _,
                 "last_name" => _,
                 "registration_id" => _
               },
               "account" => %{
                 "id" => _,
                 "agency" => _,
                 "number" => _,
                 "balance" => 100_000
               }
             } = response
    end

    test "without agency" do
      params = Keyword.put(@valid_user_data, :agency, "abc")

      response =
        build_conn()
        |> post("/api/signup", params)
        |> json_response(400)

      assert %{
               "account" => nil,
               "error" => %{"account" => "invalid agency number", "user" => nil},
               "user" => nil
             } = response
    end

    test "with invalid user data" do
      build_conn()
      |> post("/api/signup", @valid_user_data)
      |> json_response(200)

      # duplicate an enty
      response =
        build_conn()
        |> post("/api/signup", @valid_user_data)
        |> json_response(400)

      %{
        "account" => nil,
        "error" => %{
          "account" => nil,
          "user" => %{"registration_id" => ["has already been taken"]}
        },
        "user" => nil
      } = response
    end
  end
end
