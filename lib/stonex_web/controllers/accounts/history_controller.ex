defmodule StonexWeb.Accounts.HistoryController do
  @moduledoc """
  Endpoint for retrieving transaction history
  for an accont, given filters and available
  only for the account owned by the requester user
  """

  use StonexWeb, :controller

  alias Stonex.Accounts.{Account, Repository}

  @doc """
  Receives an account ID and finds, alongside
  the current user for Guardian, the account's
  transaction history based on "all", "year", "month"
  and "day" filters on the "?filter=" query
  """
  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, %{"account_id" => account_id} = params) do
    user = Guardian.Plug.current_resource(conn)
    filter = history_filter_param(params)

    case Repository.account_by_user(user, account_id) do
      %Account{} = account ->
        history = Repository.list_account_history(account, filter)
        render(conn, "history.json", %{history: history})

      nil ->
        render(conn, "account_not_found.json")
    end
  end

  defp history_filter_param(params) do
    Map.get(params, "filter", "all")
    |> String.to_atom()
  end
end
