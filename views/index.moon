import Widget from require "lapis.html"

class extends Widget
  content: =>
    script: @build_url "static/js/jquery/jquery.terminal-1.5.0.min.js"
    link rel: "stylesheet", href: @build_url "static/js/jquery/jquery.terminal-1.5.0.min.css"

    script: @build_url "static/js/game.js"
    div id: "terminal"
