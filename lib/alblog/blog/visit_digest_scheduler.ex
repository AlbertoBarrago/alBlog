defmodule Alblog.Blog.VisitDigestScheduler do
  @moduledoc """
  A GenServer that schedules daily visit digest emails.
  Sends a digest at 8:00 AM UTC every day with yesterday's visit statistics.
  """
  use GenServer

  require Logger

  @default_hour 8
  @default_minute 0

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Manually trigger the daily digest (useful for testing).
  """
  def send_digest_now do
    GenServer.cast(__MODULE__, :send_digest)
  end

  @impl true
  def init(_opts) do
    # Schedule the first run
    schedule_next_run()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:send_digest, state) do
    send_daily_digest()
    schedule_next_run()
    {:noreply, state}
  end

  @impl true
  def handle_cast(:send_digest, state) do
    send_daily_digest()
    {:noreply, state}
  end

  defp send_daily_digest do
    Logger.info("[VisitDigestScheduler] Sending daily visit digest...")

    case Alblog.Blog.send_daily_visit_digest() do
      {:ok, :no_visits} ->
        Logger.info("[VisitDigestScheduler] No visits yesterday, skipping digest")

      {:ok, _email} ->
        Logger.info("[VisitDigestScheduler] Daily digest sent successfully")

      {:error, reason} ->
        Logger.error("[VisitDigestScheduler] Failed to send digest: #{inspect(reason)}")
    end
  end

  defp schedule_next_run do
    now = DateTime.utc_now()

    # Calculate the next 8:00 AM UTC
    target_today =
      now
      |> DateTime.to_date()
      |> DateTime.new!(Time.new!(@default_hour, @default_minute, 0))

    next_run =
      if DateTime.compare(now, target_today) == :lt do
        # Today's 8 AM hasn't passed yet
        target_today
      else
        # Schedule for tomorrow's 8 AM
        DateTime.add(target_today, 1, :day)
      end

    delay_ms = DateTime.diff(next_run, now, :millisecond)

    Logger.info(
      "[VisitDigestScheduler] Next digest scheduled for #{next_run} (in #{div(delay_ms, 1000)} seconds)"
    )

    Process.send_after(self(), :send_digest, delay_ms)
  end
end
