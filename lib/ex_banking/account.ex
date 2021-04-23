defmodule ExBanking.Account do
  @moduledoc """
  Module provides functions to perfom operations above account.
  Module contains type description of `Account` struct.
  """
  @default_currency "usd"
  @default_balance 0.00

  defstruct balance: @default_balance, currency: @default_currency

  @type t() :: %__MODULE__{
          balance: number(),
          currency: binary()
        }

  @doc """
  Returns created Balance with default values: default currency is `usd`. Default balance is `0.00`
  """
  @spec new :: __MODULE__.t()
  def new(), do: %__MODULE__{}

  @doc """
  Returns created Balance with given values of currency and balance.
  Balance cannot be negative value. Currency cannot be nil or empty string.
  """
  @spec new(number(), binary()) :: __MODULE__.t()
  def new(balance, currency) when balance >= 0 and is_binary(currency) and currency != "",
    do: %__MODULE__{balance: round_to_2decimals(balance), currency: currency}

  @doc """
  Increments account's balance by given amount. Returns updated `Account`.
  """
  @spec increment_balance(__MODULE__.t(), number) :: __MODULE__.t()
  def increment_balance(%__MODULE__{balance: balance} = account, amount),
    do: %{account | balance: balance + round_to_2decimals(amount)}

  @doc """
  Decrements account's balance by given amount.
  Returns `{:error, :not_enough_money}` if there is not enough money on balance to stay non negative.
  Returns updated `Account` in success case.
  """
  @spec decrement_balance(__MODULE__.t(), number) :: {:error, :not_enough_money} | __MODULE__.t()
  def decrement_balance(%__MODULE__{balance: balance}, amount)
      when balance - amount < 0,
      do: {:error, :not_enough_money}

  def decrement_balance(%__MODULE__{balance: balance} = account, amount),
    do: %{account | balance: balance - round_to_2decimals(amount)}

  @doc """
  Checks if there is enough money on balance for withdraw given amount.
  """
  @spec enough_for_withdraw?(__MODULE__.t(), number) :: boolean()
  def enough_for_withdraw?(%__MODULE__{balance: balance}, amount),
    do: balance - round_to_2decimals(amount) >= 0

  defp round_to_2decimals(number), do: number |> Kernel./(1) |> Float.round(2)
end
