defmodule PorkybankWeb.Layouts do
  use PorkybankWeb, :html
  use LiveViewNative.Layouts

  # changed from `embed_templates "layouts/*"`
  embed_templates "layouts/*.html"
end
