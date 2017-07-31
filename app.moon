lapis = require "lapis"

Users = require "models.Users"
Realms = require "models.Realms"
Events = require "models.Events"

import now from require "utility.time"

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
  -- @include "users" -- do not allow logins without interface
  @include "command"

  handle_error: (err, trace) =>
    return layout: false, err.."\n\n"..trace

  [index: "/"]: => render: true

  [cron: "/update_realms"]: =>
    if @req.parsed_url.host == "127.0.0.1"
      realms = Realms\select "WHERE true"

      for realm in *realms
        count = realm\count_characters!
        realm\update { power: math.max 0, realm.power - count }

        unless realm.name == "nullspace"
          characters = realm\get_characters!
          if realm.power <= 50
            -- warning message
            for character in *characters
              Events\create {
                target_id: character.id
                type: "msg"
                data: "[[;red;]You are starting to see black in the corners of your vision. You feel weakened, your vision blurred.]"

                x: character.x
                y: character.y
                realm: character.realm
                time: now!
              }
          elseif realm.power <= 0
            -- kick! (and message)
            for character in *characters
              character\update { x: 0, y: 0, realm: "nullspace" }
              Events\create {
                target_id: character.id
                type: "msg"
                data: "[[;red;]Suddenly, the blackness at the edge of your vision snaps around you. There is a blinding flash of light and a loud clap of thunder, followed by a chittering noise and pain as your body is crushed through static.]"

                x: character.x
                y: character.y
                realm: character.realm
                time: now!
              }
          elseif realm.power == 50
            -- recovery message
            for character in *characters
              Events\create {
                target_id: character.id
                type: "msg"
                data: "[[;lime;]The black recedes, and you feel a sense of relief as everything comes into focus again.]"

                x: character.x
                y: character.y
                realm: character.realm
                time: now!
              }
