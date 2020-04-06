defmodule SearchBot.Consumer.MessageCreate do
  @moduledoc "Handles the `MESSAGE_CREATE` gateway event."

  alias Nosedrum.Invoker.Split, as: CommandInvoker
  alias Nostrum.Struct.Message
  alias SearchBot.Confirmation

  @nosedrum_storage_implementation Nosedrum.Storage.ETS

  @spec handle(Message.t()) :: :ok | nil
  def handle(msg) do
    unless msg.author.bot do
      CommandInvoker.handle_message(msg, @nosedrum_storage_implementation)
      # GenServer.cast(Confirmation, {:MESSAGE_CREATE, msg})
    end
  end
end
