defmodule RedisTestWeb.HomeLive do
  use RedisTestWeb, :surface_live_view
  require Logger

  alias Moon.Design.{
    Table,
    Table.Column,
    Button,
    Button.IconButton,
    Form,
    Form.Field,
    Form.Input,
    Modal
  }
  alias RedisTest.Pairs

  data(pair, :any, default: %{"key" => "", "value" => ""})
  data(create_modal_open, :boolean, default: false)
  data(del_modal_open, :boolean, default: false)
  data(upd_modal_open, :boolean, default: false)
  def mount(_params, _session, socket) do
    redis_config = Application.get_env(:redis_test, :redis)

    host = redis_config[:host]
    port = redis_config[:port]

    {:ok, db_conn} = Redix.start_link(host: host, port: port)
    {
      :ok,
      socket
      |> assign(
        db_conn: db_conn,
        pairs: Pairs.list_pairs(db_conn),
        form_create: to_form(%{"key" => "", "value" => ""}),
        form_update: to_form(socket.assigns.pair)
      )
    }
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  def handle_event("do_nothing", _, socket) do
    {:noreply, socket}
  end

  def handle_event("modal_create_open", _, socket) do
    Modal.open("modal_create")

    {:noreply,
      socket
      |> assign(
        create_modal_open: true)
    }
  end

  def handle_event("modal_create_close", _, socket) do
    Modal.close("modal_create")

    {:noreply,
      socket
      |> assign(
        create_modal_open: false)
    }
  end

  def handle_event("create", %{"key" => key, "value" => value}, socket) do
    db_conn = socket.assigns.db_conn
    Process.send_after(self(), :clear_flash, 3000)

    with :ok <- validate_pair(%{"key" => key, "value" => value}),
         {:ok, "OK"} <- Pairs.create_pair(db_conn, key, value) do
      updated_pairs = Pairs.list_pairs(db_conn)
      Modal.close("modal_create")

      {:noreply,
       socket
       |> assign(
         pairs: updated_pairs,
         create_modal_open: false,
         form_create: to_form(%{"key" => "", "value" => ""})
       ) |> put_flash(:info, "Pair Created!")
      }
    else
      {:error, msg} -> {:noreply, socket |> put_flash(:error, msg)}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("modal_del_open", %{"value" => pair_key}, socket) do
    Modal.open("modal_delete")
    db_conn = socket.assigns.db_conn

    {:ok, selected_pair} = Pairs.get_pair(db_conn, pair_key)

    {:noreply,
      socket
      |> assign(
        del_modal_open: true,
        pair: selected_pair
      )
    }
  end

  def handle_event("modal_del_close", _, socket) do
    Modal.close("modal_delete")

    {:noreply,
      socket
      |> assign(
        del_modal_open: false,
        pair: %{"key" => "", "value" => ""}
      )
    }
  end

  def handle_event("delete", %{"value" => pair_key}, socket) do
    db_conn = socket.assigns.db_conn
    Modal.close("modal_delete")
    Process.send_after(self(), :clear_flash, 3000)

    case Pairs.delete_pair(db_conn, pair_key) do
      {:ok, "OK"} ->
        updated_pairs = Pairs.list_pairs(db_conn)

        {:noreply,
         socket
         |> assign(
           pairs: updated_pairs,
           del_modal_open: false,
           pair: %{"key" => "", "value" => ""}
         ) |> put_flash(:info, "Pair Deleted!")
        }

      {:error, _reason} ->
        {:noreply,
         socket
        }
    end
  end

  def handle_event("modal_upd_open", %{"value" => pair_key}, socket) do
    Modal.open("modal_update")
    db_conn = socket.assigns.db_conn

    {:ok, selected_pair} = Pairs.get_pair(db_conn, pair_key)

    {:noreply,
      socket
      |> assign(
        upd_modal_open: true,
        pair: selected_pair,
        form_update: to_form(selected_pair)
      )
    }
  end

  def handle_event("modal_upd_close", _, socket) do
    Modal.close("modal_update")

    {:noreply,
      socket
      |> assign(
        upd_modal_open: false,
        pair: %{"key" => "", "value" => ""}
      )
    }
  end

  def handle_event("update", %{"old_key" => old_key, "key" => new_key, "value" => new_value}, socket) do
    db_conn = socket.assigns.db_conn

    with :ok <- validate_pair(%{"key" => new_key, "value" => new_value}),
         {:ok, _updated_pair} <- Pairs.update_pair(db_conn, old_key, new_key, new_value) do
      updated_pairs = Pairs.list_pairs(db_conn)
      Modal.close("modal_update")
      Process.send_after(self(), :clear_flash, 3000)
      {:noreply,
       socket
       |> assign(
         pairs: updated_pairs,
         upd_modal_open: false,
         form_update: to_form(%{"key" => "", "value" => ""})
       ) |> put_flash(:info, "Pair Updated!")
      }
    else
      {:error, msg} ->  Process.send_after(self(), :clear_flash, 3000)
                        {:noreply, socket |> put_flash(:error, msg)}
    end
  end

  defp validate_pair(%{"key" => key, "value" => value}) do
    cond do
      String.trim(key) == "" or String.trim(value) == "" ->
        {:error, "Key and Value cannot be empty"}

      String.contains?(key, " ") ->
        {:error, "Key cannot contain spaces"}

      true ->
        :ok
    end
  end
end
