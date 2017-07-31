html = require "lapis.html"

class extends html.Widget
  content: =>
    html_5 ->
      head -> title @title or "Realms"
      body ->
        script src: @build_url "static/js/jquery-3.2.1.min.js"

        if @info
          div -> text @info

        noscript "This game requies JavaScript."

        div -> @content_for "inner"
