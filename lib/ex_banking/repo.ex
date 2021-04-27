defmodule ExBanking.Repo do
  use Agent

  @moduledoc """
  `Repo` provides functionality to store and update data.
  Data saved in map where name is the key of balances in different amount.
  """

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  @doc """
  Returns map containing data for the given name.
  Returns `nil` if there is no value by the given name.
  """
  @spec get_by_name(binary()) :: map() | nil
  def get_by_name(name), do: Agent.get(__MODULE__, fn state -> Map.get(state, name) end)

  @doc """
  Stores data by the given name. If value by the given name already presents, updates current value. If doesn't present – creates new.
  Always returns :ok
  """
  @spec put_by_name(binary(), map()) :: :ok
  def put_by_name(name, value),
    do: Agent.update(__MODULE__, fn state -> Map.put(state, name, value) end)
end
