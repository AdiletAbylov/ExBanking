defmodule ExBankingConcurrencyTest do
  use ExUnit.Case
  alias ExBanking.User

  describe "Very naive deposit concurrency tests ::" do
    test "Test deposit" do
      IO.puts("Testing concurrency. Please, wait.")
      ExBanking.create_user("User111q")

      for k <- 0..5 do
        if k == 4 do
          Process.sleep(500)
        end

        Task.async(fn -> ExBanking.deposit("User111q", 100, "usd") end)
      end

      Process.sleep(6000)
    end
  end
end
