defmodule PorkybankWeb.TransactionsLive do
  use PorkybankWeb, :live_view

  import Ecto.Query
  import PorkybankWeb.TransactionFormComponent, only: [transaction_form_component: 1]
  import PorkybankWeb.CategoryFormComponent, only: [category_form_component: 1]

  def render(assigns) do
    ~H"""
    <div :if={!@transactions_loaded} class="flex justify-center">
      <.spinner />
    </div>
    <div :if={@transactions_loaded} class="flex flex-col">
      <div class="flex justify-between">
        <div>
          <div class="font-bold text-zinc-400">Transactions</div>
          <div class="font-bold text-2xl text-zinc-600">
            <%= Number.Currency.number_to_currency(@total_spent, unit: @current_user.unit) %>
          </div>
          <div class="font-bold text-zinc-400 text-xs">
            <%= @start_date %> - <%= @end_date %>
          </div>
        </div>
      </div>
      <div
        :if={length(@chart_data) > 0}
        class={[if(length(@chart_data) > 7, do: "h-72", else: "h-40"), "relative"]}
      >
        <canvas
          data-chart={Poison.encode!(@chart_data)}
          id="bar-chart"
          phx-hook="chart"
          phx-update="ignore"
        >
        </canvas>
      </div>
      <div class="flex flex-col-reverse gap-3">
        <div :for={{date, transactions} <- @transactions_grouped_by_date}>
          <.row_header>
            <div class="flex w-full justify-between items-center">
              <%= date %><span><%= transactions |> Enum.reduce(0, fn transaction, acc ->
                case transaction.transaction_id in @ignored_transactions do
                true -> acc
                false ->
                  case transaction.amount do
                    amount when amount > 0 -> acc + amount
                    _ -> acc
                  end
                  end
                end) |> Number.Currency.number_to_currency(unit: @current_user.unit) %></span>
            </div>
          </.row_header>
          <.rows>
            <.row
              :for={transaction <- transactions}
              remove_message={
                if transaction.transaction_id in @ignored_transactions,
                  do: "Are you sure you want to include this transaction?",
                  else: "Are you sure you want to ignore this transaction?"
              }
              on_remove={
                if transaction.transaction_id not in @ignored_transactions and
                     @live_action != :example,
                   do: "exclude"
              }
              on_add={
                if transaction.transaction_id in @ignored_transactions and @live_action != :example,
                  do: "include"
              }
              id={transaction.transaction_id}
              phx-value-id={transaction.transaction_id}
              phx-click={if @live_action != :example, do: "edit"}
            >
              <:icon :if={get_cat(transaction, @categories)}>
                <% pfc =
                  get_cat(transaction, @categories) %>
                <.category_emoji :if={pfc} category={pfc} />
              </:icon>
              <:title>
                <span class={if is_ignored?(transaction, @ignored_transactions), do: "line-through"}>
                  <%= transaction.name %>
                </span>
              </:title>
              <:subtitle>
                <%= transaction.date %>
                <.badge :if={is_ignored?(transaction, @ignored_transactions)} color="red" size={:xs}>
                  Ignored
                </.badge>
                <.badge :if={transaction.pending} color="blue" size={:xs}>
                  Pending
                </.badge>
              </:subtitle>
              <:value>
                <span class={[
                  if(is_ignored?(transaction, @ignored_transactions), do: "line-through")
                ]}>
                  <%= Number.Currency.number_to_currency(transaction.amount, unit: @current_user.unit) %>
                </span>
              </:value>
            </.row>
          </.rows>
        </div>
      </div>
    </div>

    <.modal
      :if={@live_action == :new or @live_action == :edit}
      size={:md}
      id="transaction-form-modal"
      show
      on_cancel={JS.patch(~p"/transactions?#{PorkybankWeb.Utils.get_url_params(%{date: @date})}")}
    >
      <.transaction_form_component
        id="transaction-form"
        current_user={@current_user}
        transaction={@transaction}
        date={@date}
      />
    </.modal>

    <.modal
      :if={@live_action == :category}
      show
      size={:md}
      id="category-form-modal"
      on_cancel={JS.patch(~p"/transactions?#{PorkybankWeb.Utils.get_url_params(%{date: @date})}")}
    >
      <.category_form_component
        id="category-form"
        category={@category}
        transaction={@transaction}
        patch={
          if @transaction.transaction_id,
            do: ~p"/transactions/#{@transaction.transaction_id}/edit",
            else: ~p"/transactions/new?#{PorkybankWeb.Utils.get_url_params(%{date: @date})}"
        }
        current_user={@current_user}
      />
    </.modal>
    """
  end

  def mount(
        params,
        _session,
        %{
          assigns: %{
            live_action: :example
          }
        } = socket
      ) do
    current_user =
      Porkybank.Accounts.User
      |> where([u], u.email == "phil@test.com")
      |> Porkybank.Repo.one!()

    categories = Porkybank.Categories.get_categories(current_user.id)
    category = %Porkybank.Banking.Category{}

    {:ok,
     assign(socket, %{
       page: "transactions",
       date: params["date"],
       category: category,
       categories: categories,
       current_user: current_user,
       selected_page: :transactions
     })}
  end

  def mount(params, _session, socket) do
    categories = Porkybank.Categories.get_categories(socket.assigns.current_user.id)
    category = %Porkybank.Banking.Category{}

    {:ok,
     assign(socket, %{
       page: "transactions",
       date: params["date"],
       category: category,
       categories: categories,
       selected_page: :transactions
     })}
  end

  def handle_params(params, _uri, socket) do
    transaction =
      if params["id"] do
        Porkybank.Repo.get_by(Porkybank.Banking.PlaidTransaction, transaction_id: params["id"])
      else
        if params["category_id"] do
          category = Porkybank.Repo.get(Porkybank.Banking.Category, params["category_id"])

          %Porkybank.Banking.PlaidTransaction{
            personal_finance_category: %{"primary" => category.name}
          }
        else
          %Porkybank.Banking.PlaidTransaction{}
        end
      end

    {:noreply,
     socket
     |> get_transactions()
     |> assign(transaction: transaction)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/transactions/#{id}/edit")}
  end

  def handle_event("exclude", params, socket) do
    Porkybank.IgnoredTransactions.create(params["id"], socket.assigns.current_user)

    {:noreply, get_transactions(socket) |> push_event("chart-updated", %{})}
  end

  def handle_event("include", params, socket) do
    Porkybank.IgnoredTransactions.delete(params["id"], socket.assigns.current_user)

    {:noreply, get_transactions(socket) |> push_event("chart-updated", %{})}
  end

  def handle_event("swipe_left", %{"id" => id}, socket) do
    if id in socket.assigns.ignored_transactions do
      Porkybank.IgnoredTransactions.delete(id, socket.assigns.current_user)
      {:noreply, get_transactions(socket) |> push_event("chart-updated", %{})}
    else
      Porkybank.IgnoredTransactions.create(id, socket.assigns.current_user)
      {:noreply, get_transactions(socket) |> push_event("chart-updated", %{})}
    end
  end

  defp get_transactions(
         %{
           assigns: %{
             live_action: :example
           }
         } = socket
       ) do
    import Ecto.Query

    current_user =
      Porkybank.Accounts.User
      |> where([u], u.email == "phil@test.com")
      |> Porkybank.Repo.one!()

    socket = assign(socket, current_user: current_user)

    case Porkybank.PlaidClient.get_transactions(current_user, date: nil) do
      {:ok, transactions} ->
        put_transactions(transactions, socket) |> put_chart_data()
    end
  end

  defp get_transactions(socket) do
    date =
      if socket.assigns.date do
        Date.from_iso8601!(socket.assigns.date)
      else
        nil
      end

    user = Porkybank.Repo.preload(socket.assigns.current_user, :plaid_accounts)

    case Porkybank.PlaidClient.get_transactions(user, date: date) do
      {:ok, transactions} ->
        put_transactions(transactions, socket) |> put_chart_data()
    end
  end

  defp put_transactions(
         %{
           ignored_transactions: ignored_transactions,
           transactions: transactions,
           total_spent: total_spent,
           start_date: start_date,
           end_date: end_date,
           today: today
         },
         socket
       ) do
    transactions_grouped_by_date =
      Enum.reduce(Enum.reverse(transactions), %{}, fn transaction, acc ->
        date = transaction.date
        Map.update(acc, date, [transaction], &(&1 ++ [transaction]))
      end)

    assign(socket, %{
      transactions_grouped_by_date: transactions_grouped_by_date,
      ignored_transactions: ignored_transactions,
      transactions_loaded: true,
      transactions: transactions,
      total_spent: total_spent,
      start_date: start_date,
      end_date: end_date,
      today: today
    })
  end

  defp is_ignored?(transaction, ignored_transactions) do
    transaction.transaction_id in ignored_transactions || transaction.amount < 0
  end

  defp get_cat(transaction, categories) do
    Enum.find(categories, &(&1.name == transaction.personal_finance_category["primary"]))
  end

  defp put_chart_data(socket) do
    # chart data for chart.js library

    # y axis is category names
    # x axis is the amount spent

    chart_data =
      Enum.reduce(socket.assigns.transactions_grouped_by_date, [], fn {_date, transactions},
                                                                      acc ->
        Enum.reduce(transactions, acc, fn transaction, acc ->
          if transaction.transaction_id in socket.assigns.ignored_transactions do
            acc
          else
            amount = transaction.amount

            case get_cat(transaction, socket.assigns.categories) do
              nil ->
                acc

              %{name: name, description: description, emoji: emoji, color: color} ->
                case Enum.find(acc, &(&1.label == description || &1.label == name)) do
                  nil ->
                    acc ++
                      [
                        %{
                          label: description || name,
                          amount: amount,
                          color: color,
                          emoji: emoji,
                          amount_formatted:
                            Number.Currency.number_to_currency(amount,
                              unit: socket.assigns.current_user.unit
                            )
                        }
                      ]

                  _ ->
                    Enum.map(acc, fn
                      %{
                        label: label,
                        amount: acc_amount,
                        amount_formatted: _amount_formatted,
                        color: color,
                        emoji: emoji
                      }
                      when label == description ->
                        %{
                          label: label,
                          amount: acc_amount + amount,
                          amount_formatted:
                            Number.Currency.number_to_currency(acc_amount + amount,
                              unit: socket.assigns.current_user.unit
                            ),
                          color: color,
                          emoji: emoji
                        }

                      x ->
                        x
                    end)
                end
            end
          end
        end)
      end)
      |> Enum.sort_by(& &1.amount, &>=/2)

    socket |> assign(chart_data: chart_data)
  end
end
