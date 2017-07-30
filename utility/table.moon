deepcopy = (tab) ->
  if "table" == type tab
    copy = {}
    for key, value in pairs tab
      copy[key] = deepcopy value
    return copy

  else
    return tab

{
  :deepcopy
}
