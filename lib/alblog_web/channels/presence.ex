defmodule AlblogWeb.Presence do
  use Phoenix.Presence,
    otp_app: :alblog,
    pubsub_server: Alblog.PubSub
end
