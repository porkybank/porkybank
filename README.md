![Porkybank](priv/static/images/porkybank.png)

Porkybank is a personal finance app to help you track your daily budget using the simple formula:

> (💰 Income - 🍽️ Expenses) / 📅 Days = 💸 Cash

## Demo

<https://porkybank.io/example/overview>

## Setup

Install and start postgres:

* `brew install postgresql`
* `brew services start postgresql`

Create dev DB:

* `psql postgres`
* `CREATE DATABASE porkybank_dev;`

Install JS dependencies:

* `cd assets`
* `npm i`

Setup enviornment variables:

``` bash
export PLAID_CLIENT_ID=
export PLAID_SECRET=

export OPENAI_API_KEY=
export OPENAI_ORGANIZATION_ID=
```

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:5050`](http://localhost:5050) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: <https://www.phoenixframework.org/>
* Guides: <https://hexdocs.pm/phoenix/overview.html>
* Docs: <https://hexdocs.pm/phoenix>
* Forum: <https://elixirforum.com/c/phoenix-forum>
* Source: <https://github.com/phoenixframework/phoenix>
