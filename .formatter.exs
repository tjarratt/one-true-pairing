[
  import_deps: [:ecto, :phoenix, :phoenix_html, :phoenix_live_view],
  inputs: [
    "*.{ex,exs}",
    "priv/*/seeds.exs",
    "{config,lib,test}/**/*.{ex,exs,heex}"
  ],
  line_length: 120,
  locals_without_parens: [
    assert_that: :*,
    flunk: :*,
    live_component: :*,
    live_redirect: :*,
    on_mount: :*
  ],
  markdown: [
    line_length: 120
  ],
  plugins: [Phoenix.LiveView.HTMLFormatter, MarkdownFormatter],
  subdirectories: ["priv/*/migrations"]
]
