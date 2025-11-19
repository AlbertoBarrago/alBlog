defmodule Alblog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AlblogWeb.Telemetry,
      Alblog.Repo,
      {DNSCluster, query: Application.get_env(:alblog, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Alblog.PubSub},
      AlblogWeb.Presence,
      # Start a worker by calling: Alblog.Worker.start_link(arg)
      # {Alblog.Worker, arg},
      # Start to serve requests, typically the last entry
      AlblogWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Alblog.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlblogWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
