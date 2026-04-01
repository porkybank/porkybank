defmodule PorkybankWeb.PlaidWebhookController do
  use PorkybankWeb, :controller

  import Ecto.Query

  require Logger

  def receive(conn, %{"webhook_type" => "TRANSACTIONS", "webhook_code" => "DEFAULT_UPDATE", "item_id" => item_id} = params) do
    Logger.info("[Plaid Webhook] type=TRANSACTIONS code=DEFAULT_UPDATE item_id=#{item_id}")

    case Porkybank.Repo.one(
           from pa in Porkybank.Banking.PlaidAccount,
             where: pa.item_id == ^item_id,
             limit: 1
         ) do
      nil ->
        Logger.warning("[Plaid Webhook] No account found for item_id=#{item_id}")

      account ->
        Oban.insert(Porkybank.Workers.TransactionFetcher.new(%{user_id: account.user_id}))
        Logger.info("[Plaid Webhook] Enqueued TransactionFetcher for user_id=#{account.user_id}")
    end

    send_resp(conn, 200, "ok")
  end

  def receive(conn, params) do
    webhook_type = params["webhook_type"]
    webhook_code = params["webhook_code"]

    Logger.info("[Plaid Webhook] type=#{webhook_type} code=#{webhook_code} payload=#{inspect(params)}")

    send_resp(conn, 200, "ok")
  end
end
