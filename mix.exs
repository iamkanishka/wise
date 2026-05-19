defmodule Wise.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/iamkanishka/wise"
  @description "Production-grade Elixir client for the Wise Platform API — " <>
                 "all 42 API groups, zero external dependencies beyond HTTPoison and Jason"

  def project do
    [
      app: :wise,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex
      description: @description,
      package: package(),

      # Docs
      name: "Wise",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),

      # Test
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Dialyzer
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix],
        flags: [:error_handling, :underspecs]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Wise.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # HTTP client
      {:httpoison, "~> 2.2"},
      # JSON encoding/decoding
      {:jason, "~> 1.4"},

      # Dev / test
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:bypass, "~> 2.1", only: :test},
      {:mox, "~> 1.1", only: :test}
    ]
  end

  defp package do
    [
      name: "wise",
      maintainers: ["iamkanishka"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "Wise",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"],
      groups_for_modules: [
        Core: [Wise, Wise.Client, Wise.Config, Wise.Application],
        Services: [
          Wise.Services.Profiles,
          Wise.Services.Quotes,
          Wise.Services.Recipients,
          Wise.Services.Transfers,
          Wise.Services.Balances,
          Wise.Services.Rates,
          Wise.Services.Currencies,
          Wise.Services.Statements,
          Wise.Services.BankAccounts,
          Wise.Services.Batches,
          Wise.Services.DirectDebits,
          Wise.Services.Simulations,
          Wise.Services.Cards,
          Wise.Services.CardOrders,
          Wise.Services.CardTransactions,
          Wise.Services.SpendLimits,
          Wise.Services.SpendControls,
          Wise.Services.Disputes,
          Wise.Services.KioskCollection,
          Wise.Services.PushProvisioning,
          Wise.Services.ThreeDS,
          Wise.Services.Webhooks,
          Wise.Services.Activities,
          Wise.Services.Comparisons,
          Wise.Services.Addresses,
          Wise.Services.OAuth,
          Wise.Services.Users,
          Wise.Services.UserSecurity,
          Wise.Services.SCA,
          Wise.Services.OTT,
          Wise.Services.KYC,
          Wise.Services.KYCReview,
          Wise.Services.Cases,
          Wise.Services.Contacts,
          Wise.Services.FaceTec,
          Wise.Services.JOSE,
          Wise.Services.ClaimAccount,
          Wise.Services.MCA
        ],
        Internal: [
          Wise.Internal.RateLimiter,
          Wise.Internal.CircuitBreaker,
          Wise.Internal.Retry
        ],
        Types: [Wise.Types],
        Errors: [Wise.Error]
      ]
    ]
  end

  defp aliases do
    [
      lint: ["credo --strict", "dialyzer"],
      "test.all": ["test --cover"],
      quality: ["format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end
end
