defmodule PorkybankWeb.UserSettingsLive do
  use PorkybankWeb, :live_view
  import Ecto.Query
  import PorkybankWeb.CategoryFormComponent, only: [category_form_component: 1]

  alias Phoenix.PubSub
  alias Porkybank.Accounts
  alias Porkybank.PlaidClient
  alias Porkybank.Banking.PlaidAccount
  alias Porkybank.Repo

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account settings</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.rows>
          <.row
            :for={account <- @plaid_accounts}
            on_remove="delete_account"
            id={"account-#{account.id}"}
            remove_message="Are you sure you want to remove this account?"
          >
            <:title><%= account.institution_name %></:title>
            <:subtitle>
              <div :for={acc <- account.accounts} class="text-xs mt-1 text-zinc-500">
                <%= acc["name"] %>
                <.badge color="green" size={:xs}>
                  <%= Number.Currency.number_to_currency(
                    acc["balances"]["current"] || acc["balances"]["available"],
                    unit: @current_user.unit
                  ) %>
                </.badge>
              </div>
            </:subtitle>
            <:value>
              <div class="flex flex-col items-end">
                <div class="text-zinc-500 font-bold text-sm whitespace-nowrap	">
                  Added: <%= Date.to_string(account.inserted_at) %>
                </div>
                <div class="text-zinc-400 font-normal text-xs whitespace-nowrap">
                  Last updated: <%= Timex.Format.DateTime.Formatters.Relative.format!(
                    account.last_synced_at || Date.utc_today(),
                    "{relative}"
                  ) %>
                </div>
              </div>
            </:value>
          </.row>
          <.row>
            <:title :if={@plaid_accounts == []}>
              <div class="flex items-center gap-1">
                <div class="relative">
                  <.icon name="hero-building-library" class="text-zinc-300 h-6 w-6" />
                  <.icon
                    name="hero-x-circle-solid"
                    class="text-red-500 absolute -right-1 -top-1 h-3 w-3"
                  />
                </div>
                <span class="font-bold">No accounts connected</span>
              </div>
            </:title>
            <:subtitle :if={@plaid_accounts == []}>
              Connect a bank account to automatically import transactions.
            </:subtitle>
            <:value>
              <div class="flex gap-1 items-center">
                <div phx-hook="token" id="token">
                  <.button
                    :if={@link_token}
                    icon_name="hero-building-library"
                    id="link-button"
                    class="whitespace-nowrap"
                    variant={:shadow}
                    data-link-token={@link_token}
                    data-env={Application.get_env(:porkybank, Porkybank.PlaidClient)[:env]}
                  >
                    Add account <.icon name="hero-plus-circle-solid" class="text-green-600" />
                  </.button>
                  <.button :if={!@link_token}>
                    Loading...
                  </.button>
                  <p :if={assigns["link_error"]}>Error: <%= assigns["link_error"] %></p>
                </div>
                <.button :if={@plaid_accounts != []} variant={:shadow} phx-click="resync">
                  <.icon name="hero-arrow-path" />
                </.button>
              </div>
            </:value>
          </.row>
        </.rows>
      </div>
      <div>
        <.simple_form for={@currency_form} id="currency_form" phx-change="update_currency">
          <.input
            field={@currency_form[:currency]}
            type="select"
            label="Currency"
            required
            options={[
              "USD",
              "EUR",
              "GBP",
              "CAD",
              "AUD",
              "JPY",
              "CNY",
              "CHF",
              "SEK",
              "NZD",
              "MXN",
              "SGD",
              "HKD",
              "NOK",
              "KRW",
              "TRY",
              "RUB",
              "INR",
              "BRL",
              "ZAR",
              "AED",
              "AFN",
              "ALL",
              "AMD",
              "ANG",
              "AOA",
              "ARS",
              "AWG",
              "AZN",
              "BAM",
              "BBD",
              "BDT",
              "BGN",
              "BHD",
              "BIF",
              "BMD",
              "BND",
              "BOB",
              "BSD",
              "BTN",
              "BWP",
              "BYN",
              "BZD",
              "CDF",
              "CLF",
              "CLP",
              "COP",
              "CRC",
              "CUC",
              "CUP",
              "CVE",
              "CZK",
              "DJF",
              "DKK",
              "DOP",
              "DZD",
              "EGP",
              "ERN",
              "ETB",
              "FJD",
              "FKP",
              "GEL",
              "GGP",
              "GHS",
              "GIP",
              "GMD",
              "GNF",
              "GTQ",
              "GYD",
              "HNL",
              "HRK",
              "HTG",
              "HUF",
              "IDR",
              "ILS",
              "IMP",
              "IQD",
              "IRR",
              "ISK",
              "JEP",
              "JMD",
              "JOD",
              "KES",
              "KGS",
              "KHR",
              "KMF",
              "KPW",
              "KWD",
              "KYD",
              "KZT",
              "LAK",
              "LBP",
              "LKR",
              "LRD",
              "LSL",
              "LYD",
              "MAD",
              "MDL",
              "MGA",
              "MKD",
              "MMK",
              "MNT",
              "MOP"
            ]}
          />
        </.simple_form>
      </div>
      <div :if={@categories != []}>
        <div class="pt-8">
          <.label>Categories</.label>
          <div class="mt-4">
            <.rows>
              <.row :for={category <- @categories} id={category.id} on_remove="delete">
                <:icon :if={category}>
                  <.category_emoji category={category} />
                </:icon>
                <:title>
                  <%= category.name %>
                </:title>
                <:subtitle>
                  <%= Date.to_string(category.inserted_at) %>
                </:subtitle>
                <:value>
                  <.link navigate={~p"/users/settings/category/#{category.id}"}>
                    <.button icon_name="hero-pencil" phx-value-id={category.id} variant={:shadow}>
                      Edit
                    </.button>
                  </.link>
                </:value>
              </.row>
            </.rows>
          </div>
        </div>
      </div>
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            field={@password_form[:email]}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>

    <.modal
      :if={@live_action == :category}
      show
      size={:md}
      id="category-form-modal"
      on_cancel={JS.patch(~p"/users/settings")}
    >
      <.category_form_component
        id="category-form"
        category={@category}
        patch={~p"/users/settings"}
        current_user={@current_user}
      />
    </.modal>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(params, _session, socket) do
    PubSub.subscribe(Porkybank.PubSub, "transactions_updated_#{socket.assigns.current_user.id}")

    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    currency_changeset = Accounts.change_user_currency(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:currency_form, to_form(currency_changeset))
      |> assign(:trigger_submit, false)
      |> put_categories()
      |> put_link_token()
      |> put_plaid_accounts()
      |> apply_action(socket.assigns.live_action, params)

    {:ok, socket}
  end

  def handle_params(_unsigned_params, _uri, socket) do
    {:noreply, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("update_currency", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_currency(user, user_params) do
      {:ok, user} ->
        currency_form =
          user
          |> Accounts.change_user_currency(user_params)
          |> to_form()

        {:noreply,
         socket
         |> assign(currency_form: currency_form)
         |> put_flash(:info, "Currency updated to #{user.currency}.")
         |> push_navigate(to: ~p"/users/settings")}

      {:error, changeset} ->
        {:noreply, assign(socket, currency_form: to_form(changeset))}
    end
  end

  def handle_event(
        "plaid_success",
        %{
          "public_token" => public_token,
          "institution_name" => institution_name,
          "account_id" => account_id
        },
        socket
      ) do
    access_token = PlaidClient.get_access_token(public_token)

    PlaidAccount.changeset(%PlaidAccount{}, %{
      account_id: account_id,
      access_token: access_token,
      institution_name: institution_name
    })
    |> Ecto.Changeset.put_assoc(:user, socket.assigns.current_user)
    |> Repo.insert()

    Porkybank.Workers.TransactionFetcher.resync(socket.assigns.current_user.id)

    {:noreply,
     put_flash(socket, :info, "Bank account connected.")
     |> put_link_token()
     |> put_plaid_accounts()}
  end

  def handle_event("delete_account", %{"id" => id}, socket) do
    id = String.split(id, "-") |> List.last() |> String.to_integer()
    account = Repo.get_by!(PlaidAccount, id: id)

    account_ids =
      socket.assigns.plaid_accounts
      |> Enum.find(&(&1.id == id))
      |> Map.get(:accounts)
      |> Enum.map(& &1["account_id"])

    with {:ok, _} <- Porkybank.Repo.delete(account),
         {_n, nil} <-
           Porkybank.Repo.delete_all(
             from pt in Porkybank.Banking.PlaidTransaction,
               where: pt.account_id in ^account_ids
           ) do
      {:noreply,
       put_flash(socket, :info, "Bank account removed.")
       |> put_link_token()
       |> put_plaid_accounts()}
    else
      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Something went wrong.")}
    end
  end

  def handle_event("resync", _params, socket) do
    Porkybank.Workers.TransactionFetcher.resync(socket.assigns.current_user.id)

    {:noreply, put_flash(socket, :info, "Bank accounts resyncing.")}
  end

  def handle_event("resync_all_users", _params, socket) do
    Porkybank.Workers.TransactionFetcher.resync_all_users()

    {:noreply, put_flash(socket, :info, "All bank accounts resyncing.")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    category = Porkybank.Repo.get!(Porkybank.Banking.Category, id)

    case Porkybank.Repo.delete(category) do
      {:ok, _} ->
        put_flash(socket, :info, "Category deleted successfully.")

      {:error, _} ->
        put_flash(socket, :error, "Category could not be deleted.")
    end

    {:noreply, put_categories(socket)}
  end

  def handle_info(
        {:updated_transactions},
        socket
      ) do
    {:noreply, put_plaid_accounts(socket)}
  end

  defp apply_action(socket, :category, params) do
    category = Porkybank.Repo.get(Porkybank.Banking.Category, params["id"])

    assign(socket, :category, category)
  end

  defp apply_action(socket, _action, _params), do: socket

  defp put_link_token(socket) do
    case PlaidClient.get_link_token(socket.assigns.current_user) do
      {:ok, %{body: %{"link_token" => link_token}}} ->
        assign(socket, :link_token, link_token)

      {:error, %{"error_message" => error_message}} ->
        assign(socket, :link_error, error_message) |> assign(:link_token, nil)
    end
  end

  defp put_plaid_accounts(socket) do
    case PlaidClient.get_plaid_accounts(socket.assigns.current_user) do
      {:error, message} ->
        assign(socket, :plaid_accounts, []) |> put_flash(:error, message)

      accounts ->
        assign(socket, :plaid_accounts, accounts)
    end
  end

  defp put_categories(socket) do
    categories =
      Repo.all(
        from c in Porkybank.Banking.Category,
          where: c.user_id == ^socket.assigns.current_user.id
      )

    assign(socket, :categories, Enum.sort_by(categories, & &1.name))
  end
end
