defmodule ExBanking do
  @moduledoc """
  `ExBanking` module provides functions to work upon users and their's balance.

  """
  alias ExBanking.User
  alias ExBanking.TaskDispatcher

  @doc """
  Creates user with the given name.

  Returns `:ok` if user created successfully.

  Returns `{:error, :user_already_exists}` if user with the given name already exists.

  Returns `{:error, :wrong_arguments}` for worng arguments.
  """
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(""), do: {:error, :wrong_arguments}
  def create_user(user) when not is_binary(user), do: {:error, :wrong_arguments}

  def create_user(name) do
    name
    |> User.create()
    |> case do
      {:ok, _user} -> :ok
      {:error, :user_already_exists} -> {:error, :user_already_exists}
    end
  end

  @doc """
  Increases user’s balance in given currency by amount value.

  Returns `{:ok, new_balance}` in success case.

  Returns {:error, :wrong_arguments} for wrong arguments.

  Returns {:error, :user_does_not_exist} if user with the given name doesn't exist.

  Returns {:error, :too_many_requests_to_user} there are too many operations on this user.
  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}

  def deposit("", _, _), do: {:error, :wrong_arguments}
  def deposit(_, _, ""), do: {:error, :wrong_arguments}

  def deposit(user, amount, currency)
      when not is_binary(user) or not is_number(amount) or not is_binary(currency),
      do: {:error, :wrong_arguments}

  def deposit(user, amount, currency) do
    TaskDispatcher.perform(user, {User, :deposit, [user, amount, currency]})
    |> case do
      {:error, :too_many_requests_to_user, _} -> {:error, :too_many_requests_to_user}
      {:ok, {:ok, user}} -> {:ok, User.balance_for_currency(user, currency)}
      {:ok, {:error, :user_does_not_exist}} -> {:error, :user_does_not_exist}
    end
  end

  @doc """
  Decreases user’s balance in given currency by amount value.
  Returns `{:ok, new_balance}` in success case.

  Returns {:error, :wrong_arguments} for wrong arguments.

  Returns {:error, :not_enough_money} if user's balance smaller than withdrawing amount.

  Returns {:error, :user_does_not_exist} if user with the given name doesn't exist.

  Returns {:error, :too_many_requests_to_user} there are too many operations on this user.
  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}

  def withdraw("", _, _), do: {:error, :wrong_arguments}
  def withdraw(_, _, ""), do: {:error, :wrong_arguments}

  def withdraw(user, amount, currency)
      when not is_binary(user) or not is_number(amount) or not is_binary(currency),
      do: {:error, :wrong_arguments}

  def withdraw(user, amount, currency) do
    TaskDispatcher.perform(user, {User, :withdraw, [user, amount, currency]})
    |> case do
      {:error, :too_many_requests_to_user, _} -> {:error, :too_many_requests_to_user}
      {:ok, {:ok, user}} -> {:ok, User.balance_for_currency(user, currency)}
      {:ok, {:error, :user_does_not_exist}} -> {:error, :user_does_not_exist}
      {:ok, {:error, :not_enough_money}} -> {:error, :not_enough_money}
    end
  end

  @doc """
  Returns user's balance in given currency. Returns zero balance if user doesn't have money in given currency.

  Returns {:error, :wrong_arguments} for wrong arguments.

  Returns {:error, :user_does_not_exist} if user with the given name doesn't exist.

  Returns {:error, :too_many_requests_to_user} there are too many operations on this user.
  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}

  def get_balance("", _), do: {:error, :wrong_arguments}
  def get_balance(_, ""), do: {:error, :wrong_arguments}

  def get_balance(user, currency) when not is_binary(user) or not is_binary(currency),
    do: {:error, :wrong_arguments}

  def get_balance(user, currency) do
    TaskDispatcher.perform(user, {User, :by_name, [user]})
    |> case do
      {:ok, {:ok, user}} -> {:ok, User.balance_for_currency(user, currency)}
      {:ok, {:error, :user_does_not_exist}} -> {:error, :user_does_not_exist}
      {:error, :too_many_requests_to_user, _} -> {:error, :too_many_requests_to_user}
    end
  end

  @doc """
  Sends money from one user's balance to another user's balance.
  It makes withdraw for first user and makes deposit for second user.
  """
  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}

  def send("", _, _, _), do: {:error, :wrong_arguments}
  def send(_, "", _, _), do: {:error, :wrong_arguments}
  def send(_, _, _, ""), do: {:error, :wrong_arguments}

  def send(from_user, to_user, amount, currency)
      when not is_binary(from_user) or not is_binary(to_user) or not is_number(amount) or
             not is_binary(currency),
      do: {:error, :wrong_arguments}

  def send(from_user, to_user, amount, currency) do
    # TO-DO: Should be transaction with atomicity and rollback
    with :ok <- User.check_sender(from_user, amount, currency),
         {:ok, _} <- User.by_name(to_user),
         {:ok, sender_balance} = withdraw(from_user, amount, currency),
         {:ok, receiver_balance} = deposit(to_user, amount, currency) do
      {:ok, sender_balance, receiver_balance}
    else
      {:error, :wrong_arguments} -> {:error, :wrong_arguments}
      :not_enough_money -> {:error, :not_enough_money}
      :sender_does_not_exist -> {:error, :sender_does_not_exist}
      {:error, :user_does_not_exist} -> {:error, :receiver_does_not_exist}
      {:error, :too_many_requests_to_user, ^from_user} -> {:error, :too_many_requests_to_sender}
      {:error, :too_many_requests_to_user, ^to_user} -> {:error, :too_many_requests_to_receiver}
    end
  end
end
