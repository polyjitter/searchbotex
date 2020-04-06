defmodule SearchBot.Cogs.Leave do
  @moduledoc """

  """

  @behaviour Nosedrum.Command

  alias Nosedrum.Predicates
  alias Nostrum.Api
  alias SearchBot.Confirmation

  @impl true
  def usage, do: ["leave"]

  @impl true
  def description,
    do: """
    Makes the bot leave your guild.
    """

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_guild)]

  @impl true
  def command(msg, []) do
    prompt = "**This will make me leave the server!** Are you sure you want to do this?"

    IO.puts("dobbingo")

    when_yes = fn d ->
      Api.edit_message!(
        d[:dialog],
        content: "**Leaving server.** If you wish for me to return, add me back."
      )

      Api.leave_guild(d[:dialog].guild_id)
    end

    when_no = &Api.edit_message!(&1[:dialog], content: "**Leaving cancelled.**")

    Confirmation.run(
      msg,
      prompt,
      when_yes,
      when_no
    )
  end
end
