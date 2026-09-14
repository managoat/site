defmodule SiteTest do
  use ExUnit.Case, async: true

  @out Path.join(System.tmp_dir!(), "managoat-site-test-#{System.unique_integer([:positive])}")

  setup_all do
    Site.Build.run(@out)
    on_exit(fn -> File.rm_rf!(@out) end)
    pages = for page <- Site.Build.pages(), into: %{}, do: {page.path, read(page.path)}
    %{pages: pages}
  end

  defp read(path), do: File.read!(Path.join(@out, Site.Build.file_for(path)))

  test "every page renders with its title and card", %{pages: pages} do
    for page <- Site.Build.pages() do
      html = pages[page.path]
      assert html =~ "<title>#{page.title}</title>", page.path
      assert html =~ ~s(<meta name="description" content="#{page.description}">), page.path
      assert html =~ ~s(<link rel="canonical" href="https://managoat.com#{page.path}">), page.path
      assert html =~ ~s(data-skin="paper")
    end
  end

  test "nothing the app resolved at request time leaked through", %{pages: pages} do
    for {path, html} <- pages do
      refute html =~ "FountainWeb", path
      refute html =~ "Fountain.Brand", path
      refute html =~ "{{", path
      refute html =~ "csrf-token", path
      refute html =~ "phoenix_live_view", path
    end
  end

  test "every internal link lands on a page, a redirect, or the app", %{pages: pages} do
    site_paths = Enum.map(Site.Build.pages(), & &1.path)
    redirects = Map.keys(Site.Build.redirects())

    # Paths the app on the same host serves: the manual, the auth flow and the
    # legal pages. The manual's links are checked against the live host by
    # `mix site.check_links`, not here.
    app_prefixes = ["/docs", "/auth/", "/terms", "/privacy", "/dashboard", "/api/"]

    for {path, html} <- pages,
        [href] <- Regex.scan(~r/href="(\/[^"#?]*)/, html, capture: :all_but_first),
        href = String.trim_trailing(href, "/"),
        href = if(href == "", do: "/", else: href) do
      assert href in site_paths or href in redirects or
               String.starts_with?(href, "/site/") or
               Enum.any?(app_prefixes, &String.starts_with?(href, &1)),
             "#{path} links #{href}, which nothing serves"
    end
  end

  test "the assets every page links are in the build" do
    for {_source, published} <- Site.Assets.stylesheets() do
      assert File.exists?(Path.join(@out, published)), published
    end

    for path <- ~w(conversations team workbench workbench-mobile) do
      assert File.exists?(Path.join(@out, "site/images/apps/#{path}.jpg"))
    end
  end

  test "the code review bot page stays unlisted", %{pages: pages} do
    for {path, html} <- pages, path != "/code-review-bot" do
      refute html =~ ~s(href="/code-review-bot"), "#{path} links the unlisted page"
    end
  end

  test "Traefik sends every page and the assets to the site" do
    rule = File.read!("k8s/ingressroute.yaml")
    exact = Regex.scan(~r/Path\(`([^`]+)`\)/, rule, capture: :all_but_first) |> List.flatten()

    prefixes =
      Regex.scan(~r/PathPrefix\(`([^`]+)`\)/, rule, capture: :all_but_first) |> List.flatten()

    routed? = fn path -> path in exact or Enum.any?(prefixes, &String.starts_with?(path, &1)) end

    for page <- Site.Build.pages(), do: assert(routed?.(page.path), "#{page.path} is not routed")

    for path <- Map.keys(Site.Build.redirects()),
        do: assert(routed?.(path), "#{path} is not routed")

    assert "/site/" in prefixes

    # And nothing the app must keep: the rule is a carve-out, not a takeover.
    for path <- ~w(/docs /auth/login /dashboard /api/health /terms /privacy /health),
        do: refute(routed?.(path), "#{path} would leave the app")
  end

  test "nginx answers the redirects the build declares" do
    conf = File.read!("nginx.conf")
    assert conf =~ "absolute_redirect off;"

    for {from, to} <- Site.Build.redirects() do
      assert conf =~ "location = #{from} { return 301 #{to}; }"
    end
  end
end
