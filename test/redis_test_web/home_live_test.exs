defmodule RedisTestWeb.HomeLiveTest do
  use RedisTestWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  setup do
    {:ok, db_conn} = Redix.start_link(host: "localhost", port: 6381)
    Redix.command(db_conn, ["FLUSHDB"])
    {:ok, db_conn: db_conn}
  end

  test "renders home page with empty pairs list", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Add New Pair"
  end


  test "creates a new pair", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view |> form("#form-create", %{key: "test_key", value: "test_value"}) |> render_submit()

    assert has_element?(view, "td", "test_key")
    assert has_element?(view, "td", "test_value")
  end

  test "updates a pair", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view |> form("#form-create", %{key: "old_key", value: "old_value"}) |> render_submit()


    view |> form("#form-update", %{old_key: "old_key", key: "new_key", value: "new_value"}) |> render_submit()

    assert has_element?(view, "td", "new_key")
    assert has_element?(view, "td", "new_value")
    refute has_element?(view, "td", "old_key")
  end

  test "deletes a pair", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    view |> form("#form-create", %{key: "delete_key", value: "delete_value"}) |> render_submit()

    view |> element("button[phx-click=\"modal_del_open\"][value=\"delete_key\"]") |> render_click
    view |> element("button[phx-click=\"delete\"]") |> render_click()

    refute has_element?(view, "td", "delete_key")
  end
end
