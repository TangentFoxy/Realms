config = require "lapis.config"
import sql_password, session_secret from require "secret"

config "production", ->
  session_name "ld39"
  secret session_secret
  postgres ->
    host "127.0.0.1"
    user "postgres"
    password sql_password
    database "ld39"
  port 443
  num_workers 4
  code_cache "on"

  digest_rounds 9

config "production", ->
  session_name "devld39"
  secret session_secret
  postgres ->
    host "127.0.0.1"
    user "postgres"
    password sql_password
    database "devld39"
  port 9123
  num_workers 2
  code_cache "off"

  digest_rounds 9
