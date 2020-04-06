defmodule SearchBot.Consumer do

  use Nostrum.Consumer

  alias Nosedrum.Storage.ETS, as: CommandStorage
  alias SearchBot.Cogs
  alias SearchBot.Consumer.{
    MessageCreate,
    MessageReactionAdd
  }

  @commands %{
    "leave" => Cogs.Leave
  }

  @spec start_link :: Supervisor.on_start()
  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  @impl true
  @spec handle_event(Nostrum.Consumer.event()) :: any()
  def handle_event({:READY, _data, _ws_state}) do
    Enum.each(@commands, fn {name, cog} -> CommandStorage.add_command({name}, cog) end)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    MessageCreate.handle(msg)
  end

  def handle_event({:MESSAGE_REACTION_ADD, reaction, _ws_state}) do
    MessageReactionAdd.handle(reaction)
  end

  def handle_event(_data), do: :ok
end
