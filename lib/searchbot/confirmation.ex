defmodule SearchBot.Confirmation do
  @moduledoc """
  Uses a GenServer to create a yes/no confirmation dialog.
  This is useful when... you need a yes/no confirmation dialog.
  """

  use GenServer

  alias Nostrum.Api
  alias Nostrum.Struct.{Message, Guild.Member}
  alias Nostrum.Cache.{Me, GuildCache}

  import Task

  # Client API

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @spec run(Message.t(), Api.options() | String.t(), fun(), fun()) :: {:ok, boolean}
  def run(original_msg, prompt, yes_fun, no_fun) do
    {reactions, dialog_msg} = create_message(original_msg, prompt)

    dialog_map = %{
      original: original_msg,
      prompt: prompt,
      dialog: dialog_msg,
      reactions: reactions,
      yes: yes_fun,
      no: no_fun
    }

    GenServer.cast(__MODULE__, {:add, dialog_map})

    Process.send_after(__MODULE__, {:drop, dialog_msg.id}, 1 * 60 * 1_000)

    {:ok, dialog_msg}
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:add, dialog_map}, confirmations) do
    case dialog_map.reactions do
      true -> {:noreply, Map.put(confirmations, dialog_map.dialog.id, dialog_map)}
      false -> {:noreply, Map.put(confirmations, dialog_map.dialog.channel_id, dialog_map)}
    end
  end

  @impl true
  def handle_cast({:MESSAGE_REACTION_ADD, reaction}, confirmations) do
    with {:ok, dialog_map} <- Map.fetch(confirmations, reaction.message_id),
         false <- dialog_map.message.author.id == reaction.user_id do
      check_mark = "\xE2\x9C\x94\xEF\xB8\x8F"
      cross_mark = "\xE2\x9D\x8C"

      cond do
        reaction.emoji.name == check_mark ->
          dialog_map.yes_fun(dialog_map)

        reaction.emoji.name == cross_mark ->
          dialog_map.no_fun(dialog_map)
      end

      GenServer.cast(__MODULE__, {:drop, dialog_map[:dialog].id})
    end
  end

  @impl true
  def handle_cast({:drop, message}, confirmations) do
    Api.create_message!(message.channel_id, content: "**Confirmation timed out.**")
    {:noreply, Map.delete(confirmations, Message)}
  end

  # Internals

  defp create_message(original_msg, prompt) do

    perm_task = async fn ->
      my_id = Me.get().id
      my_member = Api.get_guild_member!(original_msg.guild_id, my_id)
      this_guild = GuildCache.get!(original_msg.guild_id)
      Member.guild_channel_permissions(
        my_member,
        this_guild,
        original_msg.channel_id
      )
    end

    permissions = await perm_task

    case Enum.member?(permissions, :add_reaction) do
      true -> {true, do_react(original_msg, prompt)}
      false -> {false, do_read(original_msg, prompt)}
    end
  end

  defp do_react(msg, prompt) do
    check_mark = "\xE2\x9C\x94\xEF\xB8\x8F"
    cross_mark = "\xE2\x9D\x8C"

    post_task = async fn ->
      Api.create_message!(msg.channel_id, prompt)
      Api.create_reaction!(msg.channel_id, msg.id, check_mark)
      Api.create_reaction!(msg.channel_id, msg.id, cross_mark)
    end

    {:ok, dialog_msg} = await post_task

    dialog_msg
  end

  defp do_read(msg, prompt) do
    new_prompt = append_read_prompt(prompt)

    post_task = async fn ->
      Api.create_message(msg.channel_id, new_prompt)
    end

    {:ok, dialog_msg} = await post_task

    dialog_msg
  end

  defp append_read_prompt(prompt) when is_map(prompt) do
    %{prompt | content: prompt[:content] <> "\n\n_Reply with (y/n)._"}
  end

  defp append_read_prompt(prompt) when is_binary(prompt) do
    prompt <> "\n\n_Reply with (y/n)._"
  end
end
