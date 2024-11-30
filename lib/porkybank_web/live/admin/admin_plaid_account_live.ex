defmodule PorkybankWeb.Admin.AdminPlaidAccountLive do
  use PorkybankWeb, :live_view_admin

  import Ecto.Query

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between items-center">
        <div class="font-bold text-zinc-400">plaid_accounts</div>
        <.button variant={:shadow} phx-click="resync_all">
          <.icon name="hero-arrow-path" />
        </.button>
      </div>
      <div class="flex flex-col gap-6 mt-4">
        <div :for={user <- @users_with_plaid_accounts}>
          <.rows>
            <.row id={user.email} phx-value-id={user.id}>
              <:title>
                <%= user.email %>
                <div :for={plaid_account <- user.plaid_accounts}>
                  <div class="text-sm font-semibold">
                    <%= plaid_account.institution_name %>
                  </div>
                  <div class="text-xs text-zinc-400 whitespace-nowrap">
                    Last synced at: <%= plaid_account.last_synced_at || "-" %>
                  </div>
                </div>
              </:title>
              <:value>
                <span class="text-zinc-400 whitespace-nowrap">
                  Number of accounts: <%= Enum.count(user.plaid_accounts) %>
                </span>
              </:value>
            </.row>
          </.rows>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, %{
       page_selected: :plaid_accounts
     })
     |> put_users_with_plaid_accounts()}
  end

  def handle_event("resync_all", _params, socket) do
    Porkybank.Workers.TransactionFetcher.resync_all_users()

    {:noreply, socket}
  end

  defp put_users_with_plaid_accounts(socket) do
    query =
      from(u in Porkybank.Accounts.User,
        preload: [:plaid_accounts]
      )

    users = Porkybank.Repo.all(query)

    users_with_plaid_accounts =
      Enum.filter(users, fn user ->
        Enum.count(user.plaid_accounts) > 0
      end)

    assign(socket, users_with_plaid_accounts: users_with_plaid_accounts)
  end
end
