defmodule PorkybankWeb.Utils do
  def get_url_params(params) do
    Map.filter(params, fn {_key, value} -> value != nil end)
  end
end
