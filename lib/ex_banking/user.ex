defmodule ExBanking.User do
  @moduledoc """
  Module contains business functions above `User`.
  Module uses `Repo` as a store.
  Module describes `User` type.
  """
  alias ExBanking.Repo
  alias ExBanking.Account
  defstruct name: "", accounts: %{}

  @type t() :: %__MODULE__{
          name: binary(),
          accounts: map()
        }

  @doc """
  Returns `{:ok, User.t()}` by given name.
  Returns `{:error, :user_does_not_exist}` if user with the given name already exists.
  """
  @spec by_name(binary) :: {:error, :user_does_not_exist} | {:ok, __MODULE__.t()}
  def by_name(name) do
    Repo.get_by_name(name)
    |> case do
      nil -> {:error, :user_does_not_exist}
      user -> {:ok, user}
    end
  end

  @doc """
  Creates user struct with the given name and stores it.
  Returns `{:error, User.t()}` in success case.
  Returns `{:error, :user_already_exists}` if user with the given name already exists.
  """
  @spec create(binary()) :: {:ok, __MODULE__.t()} | {:error, :user_already_exists}
  def create(name) do
    with nil <- Repo.get_by_name(name),
         :ok <- Repo.put_by_name(name, %__MODULE__{name: name, accounts: default_accounts()}) do
      {:ok, Repo.get_by_name(name)}
    else
      %__MODULE__{} = _user -> {:error, :user_already_exists}
    end
  end

  @doc """
  Increases user’s balance in given currency by amount value.
  If given currency account doesn't exist, it creates new account for this currency with zero balance.
  Returns `{:ok, updated_user}` for success case.
  Returns `{:error, :user_does_not_exist}` if user doesn't exist.
  """
  @spec deposit(binary(), number(), binary()) ::
          {:ok, __MODULE__.t()} | {:error, :user_does_not_exist}
  def deposit(name, amount, currency) do
    with %__MODULE__{} = user <- Repo.get_by_name(name),
         %Account{} = updated_account <- increment_balance(user, currency, amount) do
      accounts = Map.put(user.accounts, currency, updated_account)
      updated_user = Map.put(user, :accounts, accounts)
      Repo.put_by_name(name, updated_user)
      {:ok, updated_user}
    else
      nil -> {:error, :user_does_not_exist}
    end
  end

  @doc """
  Decreases user’s balance in given currency by amount value.
  If given currency account doesn't exist, it creates new account for this currency with zero balance.
  Returns `{:ok, updated_user}` for success case.
  Returns `{:error, :user_does_not_exist}` if user doesn't exist.
  Returns `{:error, :not_enough_money}` if there is no enough money on account.
  """
  @spec withdraw(binary(), number(), binary()) ::
          {:ok, __MODULE__.t()} | {:error, :user_does_not_exist | :not_enough_money}
  def withdraw(name, amount, currency) do
    with %__MODULE__{} = user <- Repo.get_by_name(name),
         %Account{} = updated_account <- decrement_balance(user, currency, amount) do
      accounts = Map.put(user.accounts, currency, updated_account)
      updated_user = Map.put(user, :accounts, accounts)
      Repo.put_by_name(name, updated_user)
      {:ok, updated_user}
    else
      nil -> {:error, :user_does_not_exist}
      {:error, :not_enough_money} -> {:error, :not_enough_money}
    end
  end

  @doc """
  Extracts balance number for given currency from `User`.
  Returns zero balance if currency account wasn't create.
  """
  @spec balance_for_currency(__MODULE__.t(), binary()) :: number()
  def balance_for_currency(user, currency),
    do: user |> account_by_currency(currency) |> Map.get(:balance)

  defp decrement_balance(user, currency, amount),
    do: user |> account_by_currency(currency) |> Account.decrement_balance(amount)

  defp increment_balance(user, currency, amount),
    do: user |> account_by_currency(currency) |> Account.increment_balance(amount)

  defp account_by_currency(%{accounts: accounts}, currency) do
    Map.get(accounts, currency)
    |> case do
      nil -> Account.new(0.0, currency)
      account -> account
    end
  end

  defp default_accounts() do
    %{currency: currency} = acc = Account.new()
    %{currency => acc}
  end
end
