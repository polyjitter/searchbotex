defmodule SearchBot.Consumer.MessageReactionAdd do
  @moduledoc "Handles the `MESSAGE_REACTION_ADD` event."

  alias Nostrum.Struct.Message.Reaction
  alias SearchBot.Confirmation

  @spec handle(Reaction.t()) :: :ok
  def handle(reaction) do
    GenServer.cast(Confirmation, {:MESSAGE_REACTION_ADD, reaction})
  end
end
