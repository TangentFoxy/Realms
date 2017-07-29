-- this instant, formatted for DB insertion
-- yes, this is duplicating a Lapis feature, can't be bothered to figure out what it was called
now = ->
  os.date "!%Y-%m-%d %X"

{
  :now
}
