defmodule StonexWeb.GuardianErrorHandler do
  @moduledoc """
  When there is an error with guardian plug authentication,
  this module builds the error message to be presented
  """

  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{error: to_string(type)})

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(401, body)
  end
end
