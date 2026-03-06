# This file contains the configuration for Credo and should be committed to version
# control. Run `mix credo` to check your code, or use `mix check` (via ex_check).
#
# Note: There is no built-in Credo check that specifically enforces `import Module, only: [...]`.
# The `Credo.Check.Readability.OnlyImportedFunctionWhenQualifiedNames` check is the closest
# related rule — it ensures that when you import a function, you call it without the module
# prefix (i.e., you actually *use* the import). Combined with our explicit `only:` imports,
# this helps maintain clean import hygiene.
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: [
          "lib/",
          "src/",
          "test/",
          "web/",
          "apps/*/lib/",
          "apps/*/src/",
          "apps/*/test/",
          "apps/*/web/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      plugins: [],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: %{
        disabled: [
          # The following checks are disabled because they produce too many issues for
          # the existing codebase. Consider enabling them incrementally.
          {Credo.Check.Design.DuplicatedCode, []},
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Refactor.ABCSize, []},
          {Credo.Check.Refactor.ModuleDependencies, []}
        ]
      }
    }
  ]
}
