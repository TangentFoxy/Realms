version = 26   -- alert user to update their client by refreshing

db = require "lapis.db"
lapis = require "lapis"
bcrypt = require "bcrypt"
help = require "help"
config = require("lapis.config").get!

import respond_to, json_params from require "lapis.application"
import split from require "utility.string"
import now, db_time_to_unix from require "utility.time"
import timeOut from require "utility.time"

Users = require "models.Users"
Characters = require "models.Characters"
Events = require "models.Events"
Items = require "models.Items"
Rooms = require "models.Rooms"
Realms = require "models.Realms"

class extends lapis.Application
  @path: "/command"

  [command: ""]: respond_to {
    GET: =>
      return layout: false, status: 405, "Method not allowed."

    POST: json_params =>
      if not @params.version or tonumber(@params.version) < version
        return layout: false, "[[;red;]An update has been pushed. Please refresh the page and try again.]\n(Server: #{version} Client: #{@params.version})"

      args = split @params.command

      if args[1] == "help"
        if args[2]
          if args[2] == "topics"
            return layout: false, help.topics!
          elseif help[args[2]]
            if args[2] == "admin"
              if @session.id
                if user = Users\find id: @session.id
                  if user.admin
                    return layout: false, help.admin
              return layout: false, "[[;red;]You do not have permission to view that page.]"
            else
              return layout: false, help[args[2]]

        else
          if @session.id
            if user = Users\find id: @session.id
              if user.admin
                return layout: false, help\build true

        return layout: false, help\build!

      elseif args[1] == "login"
        if @session.id
          if user = Users\find id: @session.id
            return layout: false, "[[;red;]You are already logged in, #{user.name}.]"
          -- else
          --   @session.id = nil
          --   return layout: false, "You were somehow logged into a non-existant account..."

        if user = Users\find name: @params.name
          if bcrypt.verify @params.password, user.digest
            @session.id = user.id
            return layout: false, "Welcome back, #{user.name}!"

        return layout: false, "[[;red;]Invalid username or password.]"

      elseif args[1] == "create"
        if @session.id
          if user = Users\find id: @session.id
            return layout: false, "[[;red;]You are already logged in as #{user.name}!]"

        local digest
        if @params.password and @params.password\len! > 0
          digest = bcrypt.digest @params.password, config.digest_rounds

        user, errMsg = Users\create {
          name: @params.name
          email: @params.email
          digest: digest
        }

        if user
          @session.id = user.id
          unless Users\find admin: true
            user\update { admin: true }

          return layout: false, "Welcome, #{user.name}!"

        else
          return layout: false, "[[;red;]#{errMsg}]"

      elseif args[1] == "report"
        output = table.concat args, " "
        local user, source_id, x, y, realm
        if @session.id
          if user = Users\find id: @session.id
            if character = user\get_character!
              source_id = character.id
              x = character.x
              y = character.y
              realm = character.realm
        unless user
          user = { name: "not logged in" }
        Events\create {
          source_id: source_id
          type: "report"
          data: "[[;white;]#{user.name}]: [[;lime;]#{output\sub 8}]"

          x: x or 0
          y: y or 0
          realm: realm or "nullspace"
          time: now!
        }
        return layout: false, "Your report has been submitted."


      elseif @session.id
        @user = Users\find id: @session.id
        @character = Characters\find user_id: @user.id
        unless @character
          @character = Characters\create { user_id: @user.id }

        if args[1] == "logout"
          @session.id = nil
          character = @user\get_character!
          character\update { time: os.date "!%Y-%m-%d %X", os.time! - (timeOut + 1) } -- time is set to just before timeOut, we leave immediately
          return layout: false, "Goodbye, #{@user.name}..."

        elseif args[1] == "whoami" or (args[1] == "who" and args[2] == "am" and args[3] == "i")
          if @user.admin
            return layout: false, "[[;white;]#{@user.name}] ([[;white;]#{@user.id}]) [[;white;]#{@user.email}]"
          else
            return layout: false, "You are [[;white;]#{@user.name}]."

        elseif args[1] == "list"
          if @user.admin
            users = Users\select "WHERE true ORDER BY name ASC"

            output = ""
            for user in *users
              output ..= "[[;white;]#{user.name}] ([[;white;]#{user.id}]) [[;white;]#{user.email}]\n"

            output ..= "[[;lime;]#{Users\count!}] users"

            return layout: false, output

        elseif args[1] == "online"
          if @user.admin
            characters = Characters\select "WHERE time >= ?", os.date "!%Y-%m-%d %X", os.time! - timeOut
            list = {}
            for character in *characters
              table.insert list, {character\get_user!.name, character.x, character.y}

            table.sort list, (a, b) -> return a[1] > b[1]
            output = ""
            for user in *list
              output ..= "[[;white;]#{user[1]}] at [[;white;]#{user[2]}],[[;white;]#{user[3]}]\n"

            output ..= "[[;lime;]#{#list}] users online"

            return layout: false, output

        elseif args[1] == "punch"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          if args[2]
            characters = @character\here!
            for character in *characters
              user = character\get_user!
              if user.name == args[2]
                -- punch them!
                local msg
                deadBody = false
                if character.health > 0
                  character\update { health: character.health - 1 }
                  if character.health <= 0
                    msg = "[[;white;]#{@user.name}] punched [[;white;]#{user.name}], killing them!"
                  else
                    msg = "[[;white;]#{@user.name}] punched [[;white;]#{user.name}]!"
                else
                  deadBody = true
                  msg = "[[;white;]#{@user.name}] punched [[;white;]#{user.name}]'s corpse. How disrespectful."

                Events\create {
                  source_id: @character.id
                  target_id: character.id
                  type: "punch"
                  data: msg

                  x: @character.x
                  y: @character.y
                  realm: @character.realm
                  time: now!
                }
                if deadBody
                  return layout: false, "You punched [[;white;]#{user.name}]'s dead body."
                else
                  if character.health <= 0
                    Items\create {
                      type: "soul"
                      data: "#{user.name}"

                      x: @character.x
                      y: @character.y
                      realm: @character.realm
                    }
                    return layout: false, "You punched [[;white;]#{user.name}], killing them!"
                  else
                    return layout: false, "You punched [[;white;]#{user.name}]!"

            return layout: false, "[[;white;]#{args[2]}] isn't here, or doesn't exist."

          else
            return layout: false, "You swing your fists wildly at nothing."

        elseif args[1] == "say"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          output = table.concat args, " "
          Events\create {
            source_id: @character.id
            type: "msg"
            data: "[[;white;]#{@user.name}] said, \"#{output\sub 5}\""

            x: @character.x
            y: @character.y
            realm: @character.realm
            time: now!
          }
          return layout: false, false

        elseif args[1] == "rename"
          if args[2]
            if @user\update { name: args[2] }
              return layout: false, "You are now [[;white;]#{@user.name}]."
            else
              return layout: false, "That name is taken."
          else
            return layout: false, "[[;red;]Invalid command syntax.]"

        elseif args[1] == "chmail"
          if args[2]
            if @user\update { email: args[2] }
              return layout: false, "Your email is now [[;white;]#{@user.email}]."
            else
              return layout: false, "That email is taken by another account."
          else
            return layout: false, "[[;red;]Invalid command syntax.]"

        elseif args[1] == "chpass"
          if @params.password and @params.password\len! > 0
            if @user\update { digest: bcrypt.digest @params.password, config.digest_rounds }
              return layout: false, "Your password has been updated."
          else
            if @user\update { digest: db.NULL }
              return layout: false, "Your password has been removed."

        elseif args[1] == "deluser"
          if @user.admin
            user = Users\find name: args[2]
            if user\delete!
              return layout: false, "[[;white;]#{user.name}] deleted."
            else
              return layout: false, "Failed to delete [[;white;]#{user.name}]."

        elseif args[1] == "revive"
          if @character.health <= 0
            if @character\update {
              health: 1
              x: 0
              y: 0
              realm: "nullspace"
            }
              Events\create {
                source_id: @character.id
                type: "msg"
                data: "[[;white;]#{@user.name}] has revived!"

                -- trying to decide whether to care or not if these are the old values or nullspace 0,0
                -- maybe I'll care later
                x: @character.x
                y: @character.y
                realm: @character.realm
                time: now!
              }
              return layout: false, "[[;lime;]You have revived!]"
            else
              return layout: false, "[[;red;]Something went wrong, please ][[;white;[report][[;red;] this error! D:]"
          else
            return layout: false, "You are not dead!"

        elseif args[1] == "look"
          room = Rooms\here @character
          items = Items\here @character
          -- print room.description, then all names of items that have them and aren't scenery, then the exits
          return layout: false, "This feature will be implemented soon(TM)."


        -- no else, because some commands can error out
        return layout: false, "[[;red;]Invalid command ']#{args[1]}[[;red;]' or invalid command syntax.]\n(See '[[;white;]help]' command.)"

      else
        return layout: false, "[[;red;]You must log in first.]"
  }

  [command_update: "/update"]: json_params =>
    if not @params.version or tonumber(@params.version) < version
      return json: { echo: "[[;red;]An update has been pushed. Please refresh the page.]\n(Server: #{version} Client: #{@params.version})" }

    elseif @session.id
      @user = Users\find id: @session.id
      @character = Characters\find user_id: @user.id
      unless @character
        @character = Characters\create { user_id: @user.id }

      @character\update { time: os.date "!%Y-%m-%d %X" } -- we are here now
      you = { name: @user.name, health: @character.health }

      rawCharacters = @character\here!
      characters = {}
      for character in *rawCharacters
        user = character\get_user!
        if character.health > 0
          characters[user.name] = { name: user.name, health: 1 } -- it's actually a boolean for if they are alive or not :P
        else
          characters[user.name] = { name: user.name, health: 0 }

      rawEvents = Events\here @character
      events = {}
      for event in *rawEvents
        unless event.type == "report"
          unless event\get_source!.id == @character.id
            if event.target_id and event.target_id == @character.id
              table.insert events, { id: event.id, msg: event.data, source: event\get_source!\get_user!.name, targeted: true, type: event.type, time: db_time_to_unix event.time }
            elseif not event.target_id
              table.insert events, { id: event.id, msg: event.data, source: event\get_source!\get_user!.name, targeted: false, type: event.type, time: db_time_to_unix event.time }

      if @user.admin
        rawEvents = Events\now!
        for event in *rawEvents
          if event.type == "report"
            table.insert events, { id: event.id, msg: event.data, type: event.type, time: db_time_to_unix: event.time }

      return json: { :you, :characters, :events }

    else
      return json: { } -- nothing, you are not logged in
