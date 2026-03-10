%{
  configs: [
    %{
      name: "default",
      files: %{
        included: [
          "lib/",
          "test/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      plugins: [],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: %{
        extra: [
          {Credo.Check.Design.AliasUsage, [priority: :low, if_nested_deeper_than: 3, if_called_more_often_than: 3]},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, [parens: true]},
          {CredoExplicitOverImplicit.Imports, []}
        ],
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
