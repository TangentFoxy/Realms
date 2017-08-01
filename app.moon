version = 29
lapis = require "lapis"

Characters = require "models.Characters"
Events = require "models.Events"
Realms = require "models.Realms"
Users = require "models.Users"

import respond_to, json_params from require "lapis.application"
import report_error from require "utility.string"
import now from require "utility.time"
import parseCommand from require "commands"

class extends lapis.Application
  layout: "layout"

  handle_error: (err, trace) =>
    return layout: false, report_error(@, err, trace)

  @include "githook"

  [index: "/"]: => render: true

  [execute_commands: "/command"]: respond_to {
    POST: json_params =>
      if not @params.version or tonumber(@params.version) < version
        return json: { version: version }

      if @session.id
        @user = Users\find id: @session.id
        unless @user
          @session.id = nil -- invalid session (may be a user that was deleted)
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

  "/test": json_params =>

    local recursive_print
    recursive_print = (tab, depth=0) ->
      output = ""
      for key, value in pairs tab
        output ..= "#{string.rep " ", depth}#{key}=#{value}\n"
        if "table" == type value
          output ..= recursive_print value, depth+1
      return output
    output = recursive_print @params
    return layout: false, output

  "/command/update": =>
    return json: { nope: "nothing" } -- squelch errors client-side as well as server-side for now

  [update_realms: "/update_realms"]: =>
    if @req.parsed_url.host == "127.0.0.1"
      realms = Realms\select "WHERE true"

      for realm in *realms
        count = realm\get_character_count!
        realm\update { power: math.max 0, realm.power - count }

        unless realm.name == "nullspace"
          local message
          characters = realm\get_characters!
          if realm.power <= 50
            message = "[[;red;]You are starting to see black in the corners of your vision. You feel weakened, your vision blurred.]"
          elseif realm.power <= 0
            message = "[[;red;]Suddenly, the blackness at the edge of your vision snaps around you. There is a blinding flash of light and a loud clap of thunder, followed by a chittering noise and pain as your body is crushed through static.]"
            for character in *characters
              character\update { x: 0, y: 0, realm: "nullspace" }
          -- NOTE this have been commented out because it doesn't work as intended
          -- elseif realm.power == 50
          --   message = "[[;lime;]The black recedes, and you feel a sense of relief as everything comes into focus again.]"

          if msg
            for character in *characters
              Events\create {
                target_id: character.id
                type: "msg"
                data: message
                time: now!
                -- these shouldn't matter, it is targeted
                x: character.x
                y: character.y
                realm: character.realm
              }

      return layout: false, "Success."
