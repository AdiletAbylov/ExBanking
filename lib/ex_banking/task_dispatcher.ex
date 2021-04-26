defmodule ExBanking.TaskDispatcher do
  @moduledoc """
  This module provides very naive functionality to manage, queue and performs tasks above user.
  """
  use GenServer

  @max_tasks 10

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def init(init_args) do
    {:ok, init_args}
  end

  @doc """
  Performs given function upon given username.
  Each user has a limit of performing tasks. By default, this limit is 10.
  If limit is reached, function returns `{:error, too_many_requests_to_user}` immediately and do not run function.
  Returns `{:ok, function_result}`.
  """
  @spec perform(binary(), mfa()) :: {:ok, any()} | {:error, :too_many_requests_to_user}
  def perform(username, mfa) do
    GenServer.call(__MODULE__, {:could_perform?, username})
    |> case do
      false ->
        {:error, :too_many_requests_to_user, username}

      true ->
        response = GenServer.call(__MODULE__, {:exec, mfa})
        GenServer.call(__MODULE__, {:decrement_count, username})
        {:ok, response}
    end
  end

  def handle_call({:could_perform?, username}, _from, state) do
    could_perform = could_perform?(username, state)

    new_state =
      could_perform
      |> case do
        true -> update_count(username, state, 1)
        false -> state
      end

    {:reply, could_perform, new_state}
  end

  def handle_call({:decrement_count, username}, _from, state) do
    {:reply, :ok, update_count(username, state, -1)}
  end

  def handle_call({:exec, {module, func, args}}, _from, state) do
    {:reply, Kernel.apply(module, func, args), state}
  end

  defp update_count(username, state, amount) do
    state
    |> Map.get_and_update(username, fn value ->
      case value do
        nil -> {value, 0}
        value -> {value, value + amount}
      end
    end)
    |> elem(1)
  end

  defp could_perform?(username, state),
    do:
      state
      |> Map.get(username, 0)
      |> Kernel.+(1)
      |> Kernel.<(@max_tasks)
end
