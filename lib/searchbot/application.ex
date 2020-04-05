defmodule SearchBot.Application do
  @moduledoc """
    The entry point for search.
    Starts the required processes, including the gateway consumer supervisor.

    A lot of this is taken from bolt on github.
    https://github.com/jchristgit/bolt/
    Thanks for your hard work!
  """

  require Logger
  use Application

  @impl true
  @spec start(Application.start_type(), term()
    ) :: {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, term()}
  def start(_type, _args) do
    children = [
      SearchBot.ConsumerSupervisor,
      SearchBot.Confirmation,
      Nosedrum.Storage.ETS,
    ]

    options = [strategy: :rest_for_one, name: SearchBot.Supervisor]
    Supervisor.start_link(children, options)
  end

end
