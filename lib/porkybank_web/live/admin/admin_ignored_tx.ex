defmodule PorkybankWeb.Admin.AdminIgnoredTransactionsLive do
  use PorkybankWeb, :live_view_admin

  import Ecto.Query

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between items-center">
        <div class="font-bold text-zinc-400">ignored_transactions</div>
      </div>
      <div class="flex flex-col gap-6 mt-4">
        <div :for={ignored_transaction <- @ignored_transactions}>
          <.rows>
            <.row id={ignored_transaction.id} phx-value-id={ignored_transaction.id}>
              <:title>
                <%= ignored_transaction.reason %>
              </:title>
              <:subtitle>
                <%= Date.to_string(ignored_transaction.inserted_at) %>
              </:subtitle>
              <:subtitle>
                <br /> tx id: <%= ignored_transaction.transaction_id %>
              </:subtitle>
              <:value>
                <span class="text-zinc-400 whitespace-nowrap">
                  <%= ignored_transaction.user.email %>
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
       page_selected: :ignored_transactions
     })
     |> put_ignored_transactions()}
  end

  defp put_ignored_transactions(socket) do
    query =
      from(u in Porkybank.Banking.IgnoredTransaction,
        preload: [:user],
        order_by: [desc: u.inserted_at]
      )

    ignored_transactions = Porkybank.Repo.all(query)

    assign(socket,
      ignored_transactions: ignored_transactions
    )
  end
end
