html = require "lapis.html"

class extends html.Widget
  content: =>
    html_5 ->
      head -> title @title or "CHANGEME"
      body ->
        if @info
          div -> @info
        div -> @content_for "inner"
