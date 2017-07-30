lapis = require "lapis"

Users = require "models.Users"
Realms = require "models.Realms"

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
    -- if @session.id
    --   @user = Users\find id: @session.id
    --   @character = @user\get_character!

    render: true

  [cron: "/update_realms"]: =>
    if @req.host == "127.0.0.1"
      realms = Realms\select "WHERE true"
      for realm in *realms
        count = realm\count_characters!
        realm\update { power: math.max 0, realm.power - count }
