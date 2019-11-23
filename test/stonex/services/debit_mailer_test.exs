defmodule Stonex.Services.DebitMailerTest do
  use Stonex.DataCase

  doctest Stonex.Services.DebitMailer

  import Mock

  describe "debit mailer service send_debit_email/3" do
    test "generate message parts" do
      {:ok, user} =
        Stonex.Users.Repository.signup(%{
          email: "duzzifelipe@gmail.com",
          first_name: "Felipe",
          last_name: "Duzzi",
          password: "sT0n3TEST",
          password_confirmation: "sT0n3TEST",
          registration_id: "397.257.568-86"
        })

      {:ok, account} =
        Stonex.Accounts.Repository.create_account(
          user,
          1
        )

      now = NaiveDateTime.utc_now()
      date_now = NaiveDateTime.to_iso8601(now)

      with_mocks([{NaiveDateTime, [], [to_iso8601: fn _ -> date_now end, utc_now: fn -> now end]}]) do
        # there is no transaction, but it simulates
        message = Stonex.Services.DebitMailer.send_debit_email(user, account, 100_000)

        assert message == """
               From: "Felipe Duzzi" <duzzifelipe@stone.com.br>
               To: Felipe Duzzi <duzzifelipe@gmail.com>
               Cc: contact@stone.com.br
               Date: #{date_now}
               Subject: There was a debit on your account

               Hello Felipe.
               This is just a reminder that R$1.000,00 was debited from your account.

               Account:
               Agency: #{account.agency}
               Number: #{account.number}

               Your business's best account,
               Stone
               """
      end
    end
  end
end
