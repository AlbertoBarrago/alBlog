defmodule SimpleCrudWeb.Presence do
  use Phoenix.Presence,
    otp_app: :simple_crud,
    pubsub_server: SimpleCrud.PubSub
end
