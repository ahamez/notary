import Config

config :notary,
  http_port: {:env, "NOTARY_HTTP_PORT", "3000"},
  secret_key: {:env, "NOTARY_SECRET_PATH"},
  oidc: {:env, "NOTARY_OIDC_JSON_PATH"}

import_config "#{Mix.env()}.exs"
