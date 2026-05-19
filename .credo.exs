%{
  configs: [
    %{
      name: "default",
      files: %{included: ["lib/", "test/"], excluded: []},
      strict: true,
      color: true,
      checks: [
        {Credo.Check.Consistency.TabsOrSpaces},
        {Credo.Check.Design.AliasUsage, priority: :low},
        {Credo.Check.Readability.ModuleDoc},
        {Credo.Check.Readability.FunctionNames},
        {Credo.Check.Warning.IoInspect},
        {Credo.Check.Refactor.Nesting, max_nesting: 3}
      ]
    }
  ]
}
