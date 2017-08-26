use Mix.Config
alias Dogma.Rule

config :dogma,
  rule_set: Dogma.RuleSet.All,

  override: [
    %Rule.LineLength{max_length: 90},
    %Rule.PipelineStart{enabled: false},
    %Rule.TakenName{enabled: false},
  ]
