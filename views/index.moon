import Widget from require "lapis.html"

class extends Widget
  content: =>
    script: @build_url "static/js/game.js"
    div id: "terminal"
