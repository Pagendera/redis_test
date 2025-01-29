defmodule RedisTestWeb.Router do
  use RedisTestWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RedisTestWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", RedisTestWeb do
    pipe_through :browser

    live "/", HomeLive, :home
  end
end
