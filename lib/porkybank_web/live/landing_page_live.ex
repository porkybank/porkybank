defmodule PorkybankWeb.LandingPageLive do
  use PorkybankWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col flex-1 justify-between">
      <div>
        <.header class="text-center">
          Welcome to Porkybank 🐷
          <:subtitle>
            A simple, powerful, and secure budgeting app for individuals and families.
          </:subtitle>
        </.header>

        <.header>
          How does it work?
        </.header>
        <.label>
          1. Start with your income
        </.label>
        <.description>
          Let's say you make <b>$5,000</b> a month.
        </.description>

        <div class="mt-2" />

        <.label>
          2. Subtract your monthly expenses
        </.label>
        <.description>
          Rent, groceries, utilities, etc, costs you <b>$3,000</b> a month.
        </.description>

        <div class="mt-2" />

        <.label>
          3. Automatically track your spending
        </.label>
        <.description>
          <b>$2,000</b> left to spend.
        </.description>
        <div class="mt-2" />
        <.label>
          Daily Budget: <b class="text-green-600">$66.67</b>
        </.label>
        <.description>
          That's Porkybank in a nutshell.
        </.description>

        <div class="mt-8" />
        <.header>
          Ready to get started?
        </.header>
        <.description>
          <.link href={~p"/users/register"}>
            <.button phx-value="/users/register" variant={:shadow}>
              Create an account
            </.button>
          </.link>
          or <.link href={~p"/example/overview"} class="text-blue-600">see it in action</.link>
        </.description>

        <div class="mt-8" />
        <.header>
          Why is this so simple?
        </.header>
        <.description>
          I built Porkybank for myself, and I'm sharing it with you. I hope you find it as useful as I do.
          If you have any questions, feedback, or feature requests, please don't hesitate to reach out. You can find me at philip.n.london at gmail.com.
        </.description>
      </div>
    </div>
    """
  end
end
