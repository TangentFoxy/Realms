html = require "lapis.html"

class extends html.Widget
  content: => @content_for "inner"
