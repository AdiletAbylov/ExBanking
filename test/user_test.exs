defmodule ExBanking.UserTest do
  use ExUnit.Case
  alias ExBanking.User
  alias ExBanking.Account

  test "test user creation and storing" do
    assert {:ok, %User{name: "test user"}} = User.create("test user")

    assert {:ok,
            %User{
              name: "test user",
              accounts: %{"usd" => %Account{currency: "usd", balance: 0.0}}
            }} = User.by_name("test user")
  end

  test "test creation of user with already existed name" do
    assert {:ok, %User{name: "John"}} = User.create("John")
    assert {:error, :user_already_exists} = User.create("John")
  end

  test "test looking for non-existent user" do
    assert {:error, :user_does_not_exist} = User.by_name("whoami")
  end

  test "test deposit in different currencies" do
    {:ok, %{name: name}} = User.create("Han Solo")

    assert {:ok, user} = User.deposit(name, 10, "usd")
    assert 10 == User.balance_for_currency(user, "usd")

    assert {:ok, user} = User.deposit(name, 100, "usd")
    assert 110 == User.balance_for_currency(user, "usd")

    assert {:ok, user} = User.deposit(name, 50, "eur")
    assert 50 == User.balance_for_currency(user, "eur")

    assert {:ok, user} = User.deposit(name, 20, "eur")
    assert 70 == User.balance_for_currency(user, "eur")
  end

  test "test deposit for non-existent user" do
    assert {:error, :user_does_not_exist} = User.deposit("hackername", 10, "usd")
  end

  test "test withdraw in different currencies" do
    {:ok, %{name: name}} = User.create("Leah Solo")

    assert {:ok, _} = User.deposit(name, 10, "usd")
    assert {:ok, user} = User.withdraw(name, 5, "usd")
    assert 5 == User.balance_for_currency(user, "usd")

    assert {:ok, _} = User.deposit(name, 90, "eur")
    assert {:ok, user} = User.withdraw(name, 50, "eur")
    assert 40 == User.balance_for_currency(user, "eur")
  end

  test "test withdraw balance for non-existent user" do
    assert {:error, :user_does_not_exist} = User.withdraw("kaktus", 50, "eur")
  end

  test "test withdraw balance with not enough funds" do
    {:ok, %{name: name}} = User.create("Ben Solo")

    assert {:ok, _} = User.deposit(name, 10, "usd")
    assert {:error, :not_enough_money} = User.withdraw(name, 15, "usd")
  end
end
