defmodule SearchBotTest do
  use ExUnit.Case
  doctest SearchBot

  test "greets the world" do
    assert SearchBot.hello() == :world
  end
end
