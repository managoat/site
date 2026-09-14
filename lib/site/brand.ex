defmodule Site.Brand do
  @moduledoc """
  The hosted product's name and its asset bundle.

  The pages used to read these from `Fountain.Brand` at request time, where
  `PRODUCT_NAME` and `BRAND_ASSETS_URL` set them. This site is one deployment's
  copy, so they are constants. Bump `@assets_url` when the pixels change (a new
  `vN/` prefix; the bundle recipe is in the fountain repo's memory of
  BRAND_ASSETS_URL).
  """

  @name "Managoat"
  @engine "Fountain"
  @assets_url "https://share.files.inevitable.fyi/managoat/brand/v2"
  @assets ~w(app-icon.png apple-touch-icon.png favicon-32x32.png favicon-16x16.png favicon.ico og-card.png mark-mono.png)

  @doc "The hosted product."
  def name, do: @name

  @doc "The engine it runs: the AGPL server, CLI and SDKs."
  def engine, do: @engine

  @doc "True: this site sells a branded instance of the engine."
  def hosted?, do: true

  @doc "The absolute URL of one file in the brand bundle."
  def asset(name) when name in @assets, do: @assets_url <> "/" <> name

  @doc "Where the site is published; every absolute link and card URL starts here."
  def site_url, do: "https://managoat.com"

  @doc "The engine's repository."
  def repo_url, do: "https://github.com/managoat/fountain"
end
