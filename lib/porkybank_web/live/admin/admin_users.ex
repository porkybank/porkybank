defmodule PorkybankWeb.Admin.AdminUsersLive do
  use PorkybankWeb, :live_view_admin

  import Ecto.Query

  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between items-center">
        <div class="font-bold text-zinc-400">users</div>
      </div>
      <div class="flex flex-col gap-6 mt-4">
        <div :for={user <- @users}>
          <.rows>
            <.row id={user.email}>
              <:title>
                <%= user.email %>
              </:title>
              <:subtitle>
                Num. of plaid accounts: <%= Enum.count(user.plaid_accounts) %>
              </:subtitle>
              <:value>
                <span class="text-zinc-400 whitespace-nowrap">
                  <%= Date.to_string(user.inserted_at) %>
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
       page_selected: :users
     })
     |> put_users()}
  end

  defp put_users(socket) do
    query =
      from(u in Porkybank.Accounts.User,
        preload: [:plaid_accounts],
        order_by: [desc: u.inserted_at]
      )

    users = Porkybank.Repo.all(query)

    assign(socket,
      users: users
    )
  end
end
