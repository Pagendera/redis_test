defmodule RedisTest.Pairs do
  def create_pair(db_conn, key, value) do
    Redix.command(db_conn, ["SET", key, value])
  end

  def list_pairs(db_conn) do
    case Redix.command(db_conn, ["KEYS", "*"]) do
      {:ok, keys} when is_list(keys) and keys != [] ->
        case Redix.command(db_conn, ["MGET" | keys]) do
          {:ok, values} ->
            Enum.map(Enum.zip(keys, values), fn {key, value} ->
              %{"key" => key, "value" => value}
            end)

          {:error, reason} ->
            {:error, {:fetch_values_failed, reason}}
        end

      {:ok, []} ->
        []

      {:error, reason} ->
        {:error, {:fetch_keys_failed, reason}}
    end
  end

  def get_pair(db_conn, key) do
    case Redix.command(db_conn, ["GET", key]) do
      {:ok, nil} ->
        {:ok, nil}

      {:ok, value} ->
        {:ok, %{"key" => key, "value" =>  value}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def update_pair(db_conn, old_key, new_key, new_value) do
    with {:ok, _} <- delete_pair(db_conn, old_key),
         {:ok, "OK"} <- create_pair(db_conn, new_key, new_value) do
      {:ok, %{"key" => new_key, "value" => new_value}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def delete_pair(db_conn, key) do
    case Redix.command(db_conn, ["DEL", key]) do
      {:ok, 1} ->
        {:ok, "OK"}

      {:ok, 0} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
