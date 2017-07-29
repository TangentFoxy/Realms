-- splits string into table by spaces
--  (handles duplicate spacing and tab/newline spacing as well)
split = (str) ->
  tab = {}
  for word in str\gmatch "%S+"
      table.insert tab, word
  return tab

return {
  :split
}
