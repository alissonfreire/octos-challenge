defmodule OctosChallenge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OctosChallengeWeb.Telemetry,
      OctosChallenge.Repo,
      {DNSCluster, query: Application.get_env(:octos_challenge, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: OctosChallenge.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: OctosChallenge.Finch},
      # Start a worker by calling: OctosChallenge.Worker.start_link(arg)
      # {OctosChallenge.Worker, arg},
      # Start to serve requests, typically the last entry
      OctosChallengeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OctosChallenge.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OctosChallengeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
