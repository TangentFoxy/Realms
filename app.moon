lapis = require "lapis"

class extends lapis.Application
  @before_filter =>
    u = @req.parsed_url
    if u.path != "/users/login"
      @session.redirect = "#{u.scheme}://#{u.host}#{u.path}"
    if @session.info
      @info = @session.info
      @session.info = nil

  layout: "layout"

  @include "githook"
  @include "users"
  @include "command"

  [index: "/"]: =>
    render: true
