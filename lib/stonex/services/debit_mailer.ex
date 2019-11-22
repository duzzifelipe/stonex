defmodule Stonex.Services.DebitMailer do
  @moduledoc """
  This module is a mockup for a mailer service.

  It receives data from an user and an amount that
  was debited from his/her account.
  """
  require Logger

  alias Stonex.Users.User
  alias Stonex.Accounts.Account

  @doc """
  Receives an user data and get from it
  data needed for building the email.

  ## Examples

      iex> {:ok, user} = Stonex.Users.Repository.signup(%{
      ...>   email: "duzzifelipe@gmail.com",
      ...>   first_name: "Felipe",
      ...>   last_name: "Duzzi",
      ...>   password: "sT0n3TEST",
      ...>   password_confirmation: "sT0n3TEST",
      ...>   registration_id: "397.257.568-86"
      ...> })
      ...> {:ok, account} = Stonex.Accounts.Repository.create_account(
      ...>   user,
      ...>   1
      ...> )
      ...> msg = Stonex.Services.DebitMailer.send_debit_email(user, account, 100_000)
      ...> msg =~ "This is just a reminder that R$1.000,00 was debited"
      true
  """
  @spec send_debit_email(User.t(), Account.t(), pos_integer()) :: String.t()
  def send_debit_email(
        %User{email: email, first_name: first_name, last_name: last_name},
        %Account{agency: agency, number: number},
        amount
      ) do
    message = build_message(email, first_name, last_name, agency, number, amount)
    Logger.info(message)
    message
  end

  defp build_message(email, first_name, last_name, agency, number, amount) do
    """
    From: "Felipe Duzzi" <duzzifelipe@stone.com.br>
    To: #{first_name} #{last_name} <#{email}>
    Cc: contact@stone.com.br
    Date: #{date_now()}
    Subject: There was a debit on your account

    Hello #{first_name}.
    This is just a reminder that #{format_money(amount)} was debited from your account.

    Account:
    Agency: #{agency}
    Number: #{number}

    Your business's best account,
    Stone
    """
  end

  defp date_now() do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.to_iso8601()
  end

  defp format_money(amount) do
    amount
    |> Money.new(:BRL)
    |> Money.to_string(separator: ".", delimiter: ",")
  end
end
