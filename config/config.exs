import Config

config :wise,
  base_url: "https://api.wise.com",
  sandbox_url: "https://api.wise-sandbox.com",
  timeout: 30_000,
  recv_timeout: 30_000,
  max_retries: 3,
  retry_base_delay: 500,
  retry_max_delay: 30_000,
  pool_size: 10,
  pool_timeout: 5_000

import_config "#{config_env()}.exs"
