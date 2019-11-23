defmodule StonexWeb.GuardianErrorHandler do
  @moduledoc """
  When there is an error with guardian plug authentication,
  this module builds the error message to be presented
  """

  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{message: to_string(type)})
    send_resp(conn, 401, body)
  end
end
