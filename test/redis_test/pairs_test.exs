defmodule RedisTest.PairsTest do
  use ExUnit.Case, async: true

  alias RedisTest.Pairs

  setup do
    {:ok, db_conn} = Redix.start_link(host: "localhost", port: 6381)
    Redix.command(db_conn, ["FLUSHDB"])
    {:ok, db_conn: db_conn}
  end

  test "creates a pair", %{db_conn: db_conn} do
    assert {:ok, "OK"} = Pairs.create_pair(db_conn, "test_key", "test_value")
    assert {:ok, %{"key" => "test_key", "value" => "test_value"}} = Pairs.get_pair(db_conn, "test_key")
  end

  test "lists pairs", %{db_conn: db_conn} do
    Pairs.create_pair(db_conn, "key1", "value1")
    Pairs.create_pair(db_conn, "key2", "value2")

    assert [%{"key" => "key1", "value" => "value1"}, %{"key" => "key2", "value" => "value2"}] =
             Pairs.list_pairs(db_conn) |> Enum.sort_by(& &1["key"])
  end

  test "updates a pair", %{db_conn: db_conn} do
    Pairs.create_pair(db_conn, "old_key", "old_value")
    assert {:ok, %{"key" => "new_key", "value" => "new_value"}} =
             Pairs.update_pair(db_conn, "old_key", "new_key", "new_value")
  end

  test "deletes a pair", %{db_conn: db_conn} do
    Pairs.create_pair(db_conn, "to_delete", "some_value")
    assert {:ok, "OK"} = Pairs.delete_pair(db_conn, "to_delete")
    assert {:ok, nil} = Pairs.get_pair(db_conn, "to_delete")
  end


  test "fails to delete a non-existent pair", %{db_conn: db_conn} do
    assert {:error, :not_found} = Pairs.delete_pair(db_conn, "non_existent_key")
  end

  test "gets a pair that does not exist", %{db_conn: db_conn} do
    assert {:ok, nil} = Pairs.get_pair(db_conn, "non_existent_key")
  end

  test "fails to update a non-existent pair", %{db_conn: db_conn} do
    assert {:error, _reason} = Pairs.update_pair(db_conn, "non_existent_key", "new_key", "new_value")
  end

  test "list pairs when there are no pairs", %{db_conn: db_conn} do
    assert [] = Pairs.list_pairs(db_conn)
  end
end
