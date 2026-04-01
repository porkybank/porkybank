defmodule PorkybankWeb.PlaidWebhookController do
  use PorkybankWeb, :controller

  require Logger

  def receive(conn, params) do
    webhook_type = params["webhook_type"]
    webhook_code = params["webhook_code"]

    Logger.info("[Plaid Webhook] type=#{webhook_type} code=#{webhook_code} payload=#{inspect(params)}")

    send_resp(conn, 200, "ok")
  end
end
