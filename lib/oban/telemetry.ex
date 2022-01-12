defmodule Oban.Telemetry do
  @moduledoc """
  Telemetry integration for event metrics, logging and error reporting.

  ### Initialization Events

  Oban emits the following telemetry event when an Oban supervisor is started:

  * `[:oban, :supervisor, :init]` - when the Oban supervisor is started this will execute

  The initialization event contains the following measurements:

  * `:system_time` - The system's time when Oban was started

  The initialization event contains the following metadata:

  * `:conf` - The configuration used for the Oban supervisor instance
  * `:pid` - The PID of the supervisor instance

  ### Job Events

  Oban emits the following telemetry events for each job:

  * `[:oban, :job, :start]` — at the point a job is fetched from the database and will execute
  * `[:oban, :job, :stop]` — after a job succeeds and the success is recorded in the database
  * `[:oban, :job, :exception]` — after a job fails and the failure is recorded in the database

  All job events share the same details about the job that was executed. In addition, failed jobs
  provide the error type, the error itself, and the stacktrace. The following chart shows which
  metadata you can expect for each event:

  | event        | measures                   | metadata                                                     |
  | ------------ | -------------------------- | ------------------------------------------------------------ |
  | `:start`     | `:system_time`             | `:conf`, `:job`, `:state`                                    |
  | `:stop`      | `:duration`, `:queue_time` | `:conf`, `:job`, `:state`, `:result`                         |
  | `:exception` | `:duration`, `:queue_time` | `:conf`, `:job`, `:state`, `:kind`, `:reason`, `:stacktrace` |

  #### Metadata

  * `:conf` — the executing Oban instance's config
  * `:job` — the executing `Oban.Job`
  * `:state` — one of `:success`, `:failure`, `:discard` or `:snoozed`
  * `:result` — the `perform/1` return value, included unless job failed with an exception or crash

  For `:exception` events the metadata also includes details about what caused the failure. The
  `:kind` value is determined by how an error occurred. Here are the possible kinds:

  * `:error` — from an `{:error, error}` return value. Some Erlang functions may also throw an
    `:error` tuple, which will be reported as `:error`.
  * `:exit` — from a caught process exit
  * `:throw` — from a caught value, this doesn't necessarily mean that an error occurred and the
    error value is unpredictable

  ### Engine Events

  Oban emits telemetry span events for the following Engine operations:

  * `[:oban, :engine, :init, :start | :stop | :exception]`
  * `[:oban, :engine, :refresh, :start | :stop | :exception]`
  * `[:oban, :engine, :put_meta, :start | :stop | :exception]`
  * `[:oban, :engine, :insert_job, :start | :stop | :exception]`
  * `[:oban, :engine, :insert_all_job, :start | :stop | :exception]`
  * `[:oban, :engine, :fetch_jobs, :start | :stop | :exception]`
  * `[:oban, :engine, :cancel_all_jobs, :start | :stop | :exception]`
  * `[:oban, :engine, :retry_all_jobs, :start | :stop | :exception]`

  | event        | measures       | metadata                                              |
  | ------------ | -------------- | ----------------------------------------------------- |
  | `:start`     | `:system_time` | `:conf`, `:engine`                                    |
  | `:stop`      | `:duration`    | `:conf`, `:engine`                                    |
  | `:exception` | `:duration`    | `:conf`, `:engine`, `:kind`, `:reason`, `:stacktrace` |

  Events for job-level Engine operations also include the `job`

  * `[:oban, :engine, :complete_job, :start | :stop | :exception]`
  * `[:oban, :engine, :discard_job, :start | :stop | :exception]`
  * `[:oban, :engine, :error_job, :start | :stop | :exception]`
  * `[:oban, :engine, :snooze_job, :start | :stop | :exception]`
  * `[:oban, :engine, :cancel_job, :start | :stop | :exception]`
  * `[:oban, :engine, :retry_job, :start | :stop | :exception]`

  | event        | measures       | metadata                                                      |
  | ------------ | -------------- | ------------------------------------------------------------- |
  | `:start`     | `:system_time` | `:conf`, `:engine`, `:job`                                    |
  | `:stop`      | `:duration`    | `:conf`, `:engine`, `:job`                                    |
  | `:exception` | `:duration`    | `:conf`, `:engine`, `:job`, `:kind`, `:reason`, `:stacktrace` |

  #### Metadata

  * `:conf` — the Oban supervisor's config
  * `:engine` — the module of the engine used
  * `:job` - the `Oban.Job` in question
  * `:kind`, `:reason`, `:stacktrace` — see the explanation in job metadata above

  ### Notifier Events

  Oban emits telemetry a span event each time the Notifier is triggered:

  * `[:oban, :notifier, :notify, :start | :stop | :exception]`

  | event        | measures       | metadata                                                            |
  | ------------ | -------------- | ------------------------------------------------------------------- |
  | `:start`     | `:system_time` | `:conf`, `:channel`, `:payload`                                     |
  | `:stop`      | `:duration`    | `:conf`, `:channel`, `:payload`                                     |
  | `:exception` | `:duration`    | `:conf`, `:channel`, `:payload`, `:kind`, `:reason`, `:stacktrace`  |

  #### Metadata

  * `:conf` — the Oban supervisor's config
  * `:channel` — the channel on which the notification was sent
  * `:payload` - the decoded payload that was sent
  * `:kind`, `:reason`, `:stacktrace` — see the explanation in job metadata above

  ### Plugin Events

  All the Oban plugins emit telemetry events under the `[:oban, :plugin, *]` pattern (where `*` is
  either `:start`, `:stop`, or `:exception`). You can filter out for plugin events by looking into
  the metadata of the event and checking the value of `:plugin`. The `:plugin` field is the plugin
  module that emitted the event. For example, to get `Oban.Plugins.Cron` specific events, you can
  filter for telemetry events with a metadata key/value of `plugin: Oban.Plugins.Cron`.

  Oban emits the following telemetry event whenever a plugin executes (be sure to check the
  documentation for each plugin as each plugin can also add additional metadata specific to
  the plugin):

  * `[:oban, :plugin, :start]` — when the plugin beings performing its work
  * `[:oban, :plugin, :stop]` —  after the plugin completes its work
  * `[:oban, :plugin, :exception]` — when the plugin encounters an error

  The following chart shows which metadata you can expect for each event:

  | event        | measures        | metadata                                              |
  | ------------ | --------------- | ----------------------------------------------------- |
  | `:start`     | `:system_time`  | `:conf`, `:plugin`                                    |
  | `:stop`      | `:duration`     | `:conf`, `:plugin`                                    |
  | `:exception` | `:duration`     | `:conf`, `:plugin`, `:kind`, `:reason`, `:stacktrace` |

  ## Default Logger

  A default log handler that emits structured JSON is provided, see `attach_default_logger/0` for
  usage. Otherwise, if you would prefer more control over logging or would like to instrument
  events you can write your own handler.

  Here is an example of the JSON output for the `job:stop` event:

  ```json
  {
    "args":{"action":"OK","ref":1},
    "attempt":1,
    "duration":4327295,
    "event":"job:stop",
    "id":123,
    "max_attempts":20,
    "meta":{},
    "queue":"alpha",
    "queue_time":3127905,
    "source":"oban",
    "state":"success",
    "tags":[],
    "worker":"Oban.Integration.Worker"
  }
  ```

  All timing measurements are recorded as native time units but logged in microseconds.

  ## Examples

  A handler that only logs a few details about failed jobs:

  ```elixir
  defmodule MicroLogger do
    require Logger

    def handle_event([:oban, :job, :exception], %{duration: duration}, meta, nil) do
      Logger.warn("[#\{meta.queue}] #\{meta.worker} failed in #\{duration}")
    end
  end

  :telemetry.attach("oban-logger", [:oban, :job, :exception], &MicroLogger.handle_event/4, nil)
  ```

  Another great use of execution data is error reporting. Here is an example of integrating with
  [Honeybadger][honey], but only reporting jobs that have failed 3 times or more:

  ```elixir
  defmodule ErrorReporter do
    def handle_event([:oban, :job, :exception], _, %{attempt: attempt} = meta, _) do
      if attempt >= 3 do
        context = Map.take(meta, [:id, :args, :queue, :worker])

        Honeybadger.notify(meta.reason, context, meta.stacktrace)
      end
    end
  end

  :telemetry.attach("oban-errors", [:oban, :job, :exception], &ErrorReporter.handle_event/4, [])
  ```

  [honey]: https://honeybadger.io
  """
  @moduledoc since: "0.4.0"

  require Logger

  @doc """
  Attaches a default structured JSON Telemetry handler for logging.

  This function attaches a handler that outputs logs with the following fields:

  * `args` — a map of the job's raw arguments
  * `attempt` — the job's execution atttempt
  * `duration` — the job's runtime duration, in the native time unit
  * `event` — either `job:stop` or `job:exception` depending on reporting telemetry event
  * `id` — the job's id
  * `meta` — a map of the job's raw metadata
  * `queue` — the job's queue
  * `source` — always "oban"
  * `state` — the execution state, one of "success", "failure", "discard", or "snoozed"
  * `system_time` — when the job started, in microseconds
  * `tags` — the job's tags
  * `worker` — the job's worker module

  ## Examples

  Attach a logger at the default `:info` level:

      :ok = Oban.Telemetry.attach_default_logger()

  Attach a logger at the `:debug` level:

      :ok = Oban.Telemetry.attach_default_logger(:debug)
  """
  @doc since: "0.4.0"
  @spec attach_default_logger(Logger.level()) :: :ok | {:error, :already_exists}
  def attach_default_logger(level \\ :info) do
    events = [
      [:oban, :job, :start],
      [:oban, :job, :stop],
      [:oban, :job, :exception]
    ]

    :telemetry.attach_many("oban-default-logger", events, &__MODULE__.handle_event/4, level)
  end

  @doc false
  def span(name, fun, meta \\ %{}) when is_atom(name) and is_function(fun, 0) do
    start_time = System.system_time()
    start_mono = System.monotonic_time()

    execute([:oban, name, :start], %{system_time: start_time}, meta)

    try do
      result = fun.()

      execute([:oban, name, :stop], %{duration: duration(start_mono)}, meta)

      result
    catch
      kind, reason ->
        execute(
          [:oban, name, :exception],
          %{duration: duration(start_mono)},
          Map.merge(meta, %{kind: kind, reason: reason, stacktrace: __STACKTRACE__})
        )

        :erlang.raise(kind, reason, __STACKTRACE__)
    end
  end

  defp duration(start_mono), do: System.monotonic_time() - start_mono

  @doc false
  def execute(event_name, measurements, meta) do
    :telemetry.execute(event_name, measurements, normalize_meta(meta))
  end

  defp normalize_meta(%{name: {:via, Registry, {Oban.Registry, {_pid, name}}}} = meta) do
    name =
      with {role, name} <- name do
        Module.concat([
          Oban.Queue,
          Macro.camelize(to_string(name)),
          Macro.camelize(to_string(role))
        ])
      end

    %{meta | name: name}
  end

  defp normalize_meta(meta), do: meta

  @doc false
  @spec handle_event([atom()], map(), map(), Logger.level()) :: :ok
  def handle_event([:oban, :job, event], measure, meta, level) do
    Logger.log(level, fn ->
      details = Map.take(meta.job, ~w(attempt args id max_attempts meta queue tags worker)a)

      timing =
        if event == :start do
          %{event: "job:start", source: "oban", system_time: measure.system_time}
        else
          %{
            event: "job:#{event}",
            duration: System.convert_time_unit(measure.duration, :native, :microsecond),
            queue_time: System.convert_time_unit(measure.queue_time, :native, :microsecond),
            source: "oban",
            state: meta.state
          }
        end

      details
      |> Map.merge(timing)
      |> Jason.encode_to_iodata!()
    end)
  end
end
