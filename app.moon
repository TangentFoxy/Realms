lapis = require "lapis"

Users = require "models.Users"

class extends lapis.Application
  @before_filter =>
    u = @req.parsed_url
    if u.path != "/users/login"
      @session.redirect = "#{u.scheme}://#{u.host}#{u.path}"
      @info = @session.redirect
    if @session.info
      @info = @session.info
      @session.info = nil

  layout: "layout"

  @include "githook"
  -- @include "users" -- do not allow logins without interface
  @include "command"

  handle_error: (err, trace) =>
    return layout: false, err.."\n\n"..trace

  [index: "/"]: =>
    if @session.id
      @user = Users\find id: @session.id
      @character = @user\get_character!

    render: true
