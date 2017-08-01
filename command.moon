version = 28   -- alert user to update their client by refreshing

db = require "lapis.db"
lapis = require "lapis"
bcrypt = require "bcrypt"
config = require("lapis.config").get!
help = require "help"
special = require "utility.special"

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
    POST: json_params =>
        elseif args[1] == "punch"
          if args[2]
            TARGET = table.concat args, " "
            TARGET = TARGET\sub TARGET\find(" ") + 1
            characters = @character\here!
            for character in *characters
              user = character\get_user!
              if user.name == TARGET
                -- special message if you're hitting yourself
                if character.id == @character.id
                  return layout: false, "Stop hitting yourself."
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

            -- get items, maybe punch them
            items = Items\here @character
            for item in *items
              if item.name == TARGET
                if item.special
                  return layout: false, special\handle command: "punch", user: @user, character: @character, item: item
                Events\create {
                  source_id: @character.id
                  type: "msg"
                  data: "[[;white;]#{@user.name}] punches the [[;yellow;]#{item.name}], with no effect."

                  x: @character.x
                  y: @character.y
                  realm: @character.realm
                  time: now!
                }
                return layout: false, "You punch the [[;yellow;]#{item.name}]. There is no effect."

            return layout: false, "[[;white;]#{args[2]}] isn't here, or doesn't exist."

          else
            return layout: false, "You swing your fists wildly at nothing."

        elseif args[1] == "look" or args[1] == "looks"
          room = Rooms\here @character
          rawItems = Items\here @character
          items = {}
          rawCharacters = @character\here!
          characters, deadCharacters = {}, {}
          for character in *rawCharacters
            if character.id == @character.id
              break
            user = character\get_user!
            if character.health > 0
              table.insert characters, user.name
            else
              table.insert deadCharacters, user.name
          -- print room.description, then all names of items that have them and aren't scenery (and the soul count), then users in the room, finally the exits
          output = "In [[;lime;]#{room.realm}]:\n"..room.description
          soulCount = 0
          for item in *rawItems
            if item.type == "soul"
              soulCount += 1
            elseif item.type != "scenery"
              table.insert items, item

          if #items == 1
            output ..= "\n\n".."There is a [[;yellow;]#{items[1].name}] here."
          elseif #items >= 1
            if #items < 5
              output ..= "\n\n".."There are a few items here: "
            else
              output ..= "\n\n".."There are several items here: "
            for item in *items
              output ..= "[[;yellow;]#{item.name}], "
            output = output\sub(1, -3).."."

          if soulCount > 0
            if soulCount == 1
              output ..= "\nThere is a [[;yellow;]soul] here."
            else
              output ..= "\nThere are [[;white;]#{soulCount}] [[;yellow;]souls] here."

          if #characters == 1
            output ..= "\n[[;white;]#{characters[1]}] is here."
          elseif #characters == 2
            output ..= "\n[[;white;]#{characters[1]}] and [[;white;]#{characters[2]}] are here."
          elseif #characters > 2
            output ..= "\n"
            for i = 1, #characters
              if i == #characters
                output ..= "and [[;white;]#{characters[i]}] are here."
              else
                output ..= "[[;white;]#{characters[i]}], "

          if #deadCharacters == 1
            output ..= "\n[[;white;]#{deadCharacters[1]}]'s body is here."
          elseif #deadCharacters == 2
            output ..= "\n[[;white;]#{deadCharacters[1]}] and [[;white;]#{deadCharacters[2]}] are here."
          elseif #deadCharacters > 2
            output ..= "\n"
            for i = 1, #deadCharacters
              if i == #deadCharacters
                output ..= "and [[;white;]#{deadCharacters[i]}] are here."
              else
                output ..= "[[;white;]#{deadCharacters[i]}], "

        elseif args[1] == "examine" or args[1] == "x"
          rawItems = Items\here @character
          if ITEM == "soul"
            -- TODO find first soul and say whose it is
            return layout: false, "I will do this after Ludum Dare or if I get the time."
          elseif ITEM == "souls"
            -- TODO list all soul owners and how many their are
            return layout: false, "I will do this after Ludum Dare or if I get the time."
          else
            for item in *rawItems
              if ITEM == item.name
                if item.type == "scenery" or item.type == "item"
                  return layout: false, item.data

          inventory = Items\find character_id: @character.id
          for item in *inventory
            if ITEM == item.name
              return layout: false, item.data

          return layout: false, "There is no [[;white;]#{ITEM}] here."

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
        unless event.type == "report" or event.type == "report-done"
          unless event\get_source!.id == @character.id
            if event.target_id and event.target_id == @character.id
              table.insert events, { id: event.id, msg: event.data, source: event\get_source!\get_user!.name, targeted: true, type: event.type, time: db_time_to_unix event.time }
            elseif event.type == "punch"
              table.insert events, { id: event.id, msg: event.data, source: event\get_source!\get_user!.name, targeted: false, type: event.type, time: db_time_to_unix event.time }
            elseif not event.target_id
              table.insert events, { id: event.id, msg: event.data, source: event\get_source!\get_user!.name, targeted: false, type: event.type, time: db_time_to_unix event.time }

      rawEvents = Events\targeted_not_here @character
      for event in *rawEvents
        table.insert events, { id: event.id, msg: event.data, source: event\get_source!\get_user!.name, targeted: true, type: event.type, time: db_time_to_unix event.time }

      if @user.admin
        rawEvents = Events\now!
        for event in *rawEvents
          if event.type == "report"
            table.insert events, { id: event.id, msg: event.data, type: event.type, time: db_time_to_unix: event.time }

      return json: { :you, :characters, :events }

    else
      return json: { } -- nothing, you are not logged in
