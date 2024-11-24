defmodule PorkybankWeb.Styles.CoreStyles do
  use LiveViewNative.Stylesheet, :swiftui

  ~SHEET"""
  "color-" <> color do
    foregroundStyle(to_ime(color))
  end

  "size-" <> size do
    font(system(size: to_integer(size)))
  end

  "bold" do
    fontWeight(.bold)
  end

  "p-" <> padding do
    padding(to_integer(padding))
  end

  "px-" <> padding do
    padding(.horizontal, to_integer(padding))
  end

  "py-" <> padding do
    padding(.vertical, to_integer(padding))
  end

  "pb-" <> padding do
    padding(.bottom, to_integer(padding))
  end
  """

  def class(_, _), do: {:unmatched, []}
end
