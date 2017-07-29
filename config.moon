config = require "lapis.config"
import sql_password, session_secret from require "secret"

config {"production", "development"}, ->
  session_name "CHANGEME"
  secret session_secret
  postgres ->
    host "127.0.0.1"
    user "postgres"
    password sql_password
  digest_rounds 9

config "production", ->
  postgres ->
    database "CHANGEME"
  port 443
  num_workers 4
  code_cache "on"

config "development", ->
  postgres ->
    database "devCHANGEME"
  port 9123
  num_workers 2
  code_cache "off"
