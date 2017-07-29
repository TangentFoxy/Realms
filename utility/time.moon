-- this instant, formatted for DB insertion
-- yes, this is duplicating a Lapis feature, can't be bothered to figure out what it was called
now = ->
  os.date "!%Y-%m-%d %X"

-- converts from something like "2017-07-29 12:38:18" to Unix time
db_time_to_unix = (time) ->
  tab = {
    year: tonumber time\sub 1, 4
    month: tonumber time\sub 6, 7
    day: tonumber time\sub 9, 10
    hour: tonumber time\sub 12, 13
    min: tonumber time\sub 15, 16
    sec: tonumber time\sub 18, 19
  }

  return os.time tab

{
  :now
  :db_time_to_unix
  timeOut: 30   -- how many seconds before a user is considered offline
}
