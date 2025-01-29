defmodule RedisTest.Mailer do
  use Swoosh.Mailer, otp_app: :redis_test
end
