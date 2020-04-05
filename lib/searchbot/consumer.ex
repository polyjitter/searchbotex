defmodule SearchBot.Consumer do

  alias SearchBot.Consumer.MessageCreate
  alias SearchBot.Cogs

  alias Nosedrum.Storage.ETS, as: CommandStorage
  use Nostrum.Consumer

  @commands %{
    "leave" => Cogs.Leave
  }

  @spec start_link :: Supervisor.on_start()
  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  def handle_event({:READY, _data, _ws_state}) do
    Enum.each(@commands, fn {name, cog} -> CommandStorage.add_command({name}, cog) end)
    IO.puts "Dabbing"
  end

  @impl true
  @spec handle_event(Nostrum.Consumer.event()) :: any()
  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    IO.puts "dabs."
    MessageCreate.handle(msg)
  end

  def handle_event(_data), do: :ok
end
