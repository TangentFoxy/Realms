version = 29 -- NOTE may need to change depending on whether or not I push bug fixes to running version
lapis = require "lapis"

-- NOTE may not need these
Events = require "models.Events"
Realms = require "models.Realms"
Users = require "models.Users"

import respond_to, json_params from require "lapis.application"
import report_error from require "utility.string"
import now from require "utility.time" -- NOTE may not be needed

class extends lapis.Application
  layout: "layout"

  handle_error: (err, trace) =>
    return layout: false, report_error(@, err, trace)

  @include "githook"

  [index: "/"]: => render: true

  [execute_commands: "/command"]: respond_to {
    POST: json_params =>
      if not @params.version or tonumber(@params.version) < version
        return layout: false, version

      if @session.id
        @user = Users\find id: @session.id
        @character = Characters\find user_id: @user.id
        unless @character
          @character = Characters\create { user_id: @user.id }

      result = parseCommand(@, @params.command)
      if result == nil
        return layout: false, report_error(@, @params.command, result)

      return layout: false, result

    GET: =>
      return layout: false, status: 405, "Method not allowed."
  }

  "/command/update": =>
    return layout: false, "" -- temporary squelching errors



  -- TODO rewrite this shit
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
