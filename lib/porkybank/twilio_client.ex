defmodule Porkybank.TwilioClient do
  require Logger

  @base_url "https://api.twilio.com/2010-04-01"

  def send_sms(to, body) do
    config = Application.get_env(:porkybank, __MODULE__)
    account_sid = config[:account_sid]
    auth_token = config[:auth_token]
    messaging_service_sid = config[:messaging_service_sid]

    client =
      Tesla.client([
        {Tesla.Middleware.BasicAuth, username: account_sid, password: auth_token},
        Tesla.Middleware.FormUrlencoded
      ])

    url = "#{@base_url}/Accounts/#{account_sid}/Messages.json"

    case Tesla.post(client, url, %{
           "To" => to,
           "MessagingServiceSid" => messaging_service_sid,
           "Body" => body
         }) do
      {:ok, %{status: 201}} ->
        Logger.info("[Twilio] SMS sent to #{to}")
        :ok

      {:ok, %{status: status, body: resp_body}} ->
        Logger.error("[Twilio] Failed status=#{status} body=#{inspect(resp_body)}")
        {:error, resp_body}

      {:error, reason} ->
        Logger.error("[Twilio] Error reason=#{inspect(reason)}")
        {:error, reason}
    end
  end
end
