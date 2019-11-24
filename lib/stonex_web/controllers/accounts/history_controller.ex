defmodule StonexWeb.Accounts.HistoryController do
  use StonexWeb, :controller

  alias Stonex.Accounts.{Account, Repository}

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
