defmodule PorkybankWeb.HomeLive do
  use PorkybankWeb, :live_view

  @impl true
  def render(%{format: :swiftui} = assigns) do
    ~SWIFTUI"""
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, push_navigate(socket, to: ~p"/ios/overview?#{params}")}
  end
end
