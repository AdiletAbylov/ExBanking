defmodule ExBankingTest do
  use ExUnit.Case
  alias ExBanking.User

  describe "User creation ::" do
    test "test creation" do
      assert :ok = ExBanking.create_user("Useraaa")
    end

    test "test creation negative cases" do
      ExBanking.create_user("User1q")
      assert {:error, :user_already_exists} = ExBanking.create_user("User1q")

      assert {:error, :wrong_arguments} = ExBanking.create_user("")
      assert {:error, :wrong_arguments} = ExBanking.create_user(nil)
      assert {:error, :wrong_arguments} = ExBanking.create_user(100)
    end
  end

  describe "Deposit money ::" do
    test "test deposit" do
      ExBanking.create_user("pikapika")
      assert {:ok, 100.0} = ExBanking.deposit("pikapika", 100, "usd")
      assert {:ok, 119.0} = ExBanking.deposit("pikapika", 19, "usd")
    end

    test "test deposit negative cases" do
      assert {:error, :user_does_not_exist} = ExBanking.deposit("picachu", 100, "usd")
      assert {:error, :wrong_arguments} = ExBanking.deposit(nil, nil, nil)
      assert {:error, :wrong_arguments} = ExBanking.deposit("", "", "")
      assert {:error, :wrong_arguments} = ExBanking.deposit(100, 100, 100)
      assert {:error, :wrong_arguments} = ExBanking.deposit("aa", 100, "")
    end
  end

  describe "Withdraw money ::" do
    test "test withdraw" do
      ExBanking.create_user("Girafee")
      assert {:ok, 100.0} = ExBanking.deposit("Girafee", 100, "usd")
      assert {:ok, 81.0} = ExBanking.withdraw("Girafee", 19, "usd")
      assert {:error, :not_enough_money} = ExBanking.withdraw("Girafee", 19000, "usd")
    end

    test "test withdraw negative cases" do
      assert {:error, :user_does_not_exist} = ExBanking.deposit("Aba", 100, "usd")
      assert {:error, :wrong_arguments} = ExBanking.deposit("", "", "")
      assert {:error, :wrong_arguments} = ExBanking.deposit(nil, nil, nil)
      assert {:error, :wrong_arguments} = ExBanking.deposit(100, 100, 100)
      assert {:error, :wrong_arguments} = ExBanking.deposit("Aa", 100, "")
    end
  end

  describe "Balance checking ::" do
    test "test balance checking" do
      ExBanking.create_user("paprika")
      ExBanking.deposit("paprika", 100, "usd")
      assert {:ok, 100.0} = ExBanking.get_balance("paprika", "usd")
      assert {:ok, 0.0} = ExBanking.get_balance("paprika", "rub")
    end

    test "test balance checking negative cases" do
      assert {:error, :user_does_not_exist} = ExBanking.get_balance("paprikash", "usd")
      assert {:error, :wrong_arguments} = ExBanking.get_balance("", "")
      assert {:error, :wrong_arguments} = ExBanking.get_balance(nil, nil)
      assert {:error, :wrong_arguments} = ExBanking.get_balance(100, 100)
    end
  end

  describe "Sending money ::" do
    test "test sending money from one user to another" do
      from_user_name = "Mike"
      {:ok, _from_user} = User.create(from_user_name)
      User.deposit(from_user_name, 25, "usd")
      to_user_name = "Anna"
      {:ok, _to_user} = User.create(to_user_name)
      assert {:ok, 15.0, 10.0} = ExBanking.send(from_user_name, to_user_name, 10, "usd")

      assert {:error, :not_enough_money} =
               ExBanking.send(from_user_name, to_user_name, 10000, "usd")
    end

    test "test sending money negative cases" do
      assert {:error, :sender_does_not_exist} =
               ExBanking.send("iamnoone", "someperson", 10, "usd")

      assert {:error, :wrong_arguments} = ExBanking.send(nil, nil, nil, nil)
      assert {:error, :wrong_arguments} = ExBanking.send("", "", "", "")
      assert {:error, :wrong_arguments} = ExBanking.send("Kane", "", 10, "usd")
      assert {:error, :wrong_arguments} = ExBanking.send(10, 10, 10, "usd")

      {:ok, _} = User.create("Kane")
      User.deposit("Kane", 25, "usd")
      assert {:error, :receiver_does_not_exist} = ExBanking.send("Kane", "Alice", 10, "usd")
    end
  end
end
