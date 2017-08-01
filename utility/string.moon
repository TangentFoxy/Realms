import now from require "utility.time"

Events = require "models.Events"

-- splits string into table by spaces
--  (handles duplicate spacing and tab/newline spacing as well)
split = (str) ->
  tab = {}
  for word in str\gmatch "%S+"
      table.insert tab, word
  return tab

-- takes space-separated string and puts it in alphabetical order
--  (handles weird spacing, returns with single-spacing)
alphabetize = (str) ->
  tab = split str
  table.sort tab
  return table.concat tab, " "

-- takes space-separated string and removes duplicate entries
--  (handles weird spacing, returns with single-spacing)
remove_duplicates = (str) ->
  str = split str
  tab, result = {}, {}

  for s in *str
    tab[s] = true
  for tag in pairs tab
    table.insert result, tag

  return table.concat result, " "

-- convenience function
format_error = (err) ->
  return "[[;red;]#{err}]"

-- creates an error report, and then returns a formatted string about it
report_error = (Request, err, trace) ->
  message = "[[;red;]SERVER ERROR: #{err}]"
  if trace
    message ..= "\n#{trace}"

  local report
  if Request.user
    report = Events\create {
      source_id: Request.character.id
      type: "report"
      data: message
      x: Request.character.x
      y: Request.character.y
      realm: Request.character.realm
      time: now!
    }
  else
    report = Events\create {
      type: "report"
      data: message
      time: now!
    }

  return "[[;red;]An error has occured:\n#{err}]\n[[;white;]Report ##{report.id} has been automatically filed.]"

return {
  :split
  :alphabetize
  :remove_duplicates
  :format_error
  :report_error
}
