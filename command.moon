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
              table.insert list, {character\get_user!.name, character.x, character.y, character.realm}

            table.sort list, (a, b) -> return a[1] > b[1]
            output = ""
            for user in *list
              output ..= "[[;white;]#{user[1]}] in [[;white;]#{user[4]}] at ([[;white;]#{user[2]}],[[;white;]#{user[3]}])\n"

            output ..= "[[;lime;]#{#list}] users online"

            return layout: false, output

        elseif args[1] == "punch"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
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
            character = user\get_character!
            if character\delete!
              if user\delete!
                return layout: false, "[[;white;]#{user.name}] deleted."
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

        elseif args[1] == "look" or args[1] == "looks"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
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

          output ..= "\n\nExits: "
          if room.exits\len! > 0
            if room.exits\find "n"
              output ..= "north, "
            if room.exits\find "w"
              output ..= "west, "
            if room.exits\find "s"
              output ..= "south, "
            if room.exits\find "e"
              output ..= "east, "
            output = output\sub(1, -3).."."
          else
            output ..= "none."

          return layout: false, output

        elseif args[1] == "take" or args[1] == "get"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          unless args[2]
            return layout: false, "[[;red;]Invalid command syntax.]"
          ITEM = table.concat args, " "
          ITEM = ITEM\sub ITEM\find(" ") + 1
          -- [[;white;]take] item OR soul(s) - take an item, or a soul, or multiple souls ('get' also works)
          rawItems = Items\here @character
          if ITEM == "soul"
            soul = false
            for item in *rawItems
              if item.type == "soul"
                soul = item
                break
            if soul
              name = soul.data
              if @character.souls
                @character\update { health: @character.health + 1, souls: @character.souls .. " #{name}" } -- can duplicate, not cool
              else
                @character\update { health: @character.health + 1, souls: name }
              soul\delete!
              Events\create {
                source_id: @character.id
                type: "msg"
                data: "[[;white;]#{@user.name}] has consumed a soul!"

                x: @character.x
                y: @character.y
                realm: @character.realm
                time: now!
              }
              return layout: false, "You have consumed [[;white;]#{name}]'s soul. Your HP is now [[;white;]#{@character.health}]."
            else
              return layout: false, "There are no souls to consume."

          elseif ITEM == "souls"
            soulCount = 0
            souls = {}
            for item in *rawItems
              if item.type == "soul"
                soulCount += 1
                table.insert souls, item
            if soulCount > 1
              rawCharacters = @character\here!   -- can probably optimize by making some sort of count here function
              numSouls = math.max 2, math.floor soulCount / #rawCharacters
              counter = 0
              local names
              for soul in *souls
                if names
                  names ..= " #{soul.data}"
                else
                  names = soul.data
                soul\delete!
                counter += 1
                if counter == numSouls -- only consume the correct number of souls
                  break
              if @character.souls
                @character\update { health: @character.health + numSouls, souls: @character.souls .. " #{names}" } -- again, duplications possible
              else
                @character\update { health: @character.health + numSouls, souls: names}
              Events\create {
                source_id: @character.id
                type: "msg"
                data: "[[;white;]#{@user.name}] has consumed #{numSouls} souls!"

                x: @character.x
                y: @character.y
                realm: @character.realm
                time: now!
              }
              return layout: false, "You have consumed [[;white;]#{numSouls}] souls. Your HP is now [[;white;]#{@character.health}]."
            elseif soulCount == 1
              soul = souls[1]
              -- ugly with the copy-pasting :D
              name = soul.data
              if @character.souls
                @character\update { health: @character.health + 1, souls: @character.souls .. " #{name}" } -- can duplicate, not cool
              else
                @character\update { health: @character.health + 1, souls: name }
              soul\delete!
              Events\create {
                source_id: @character.id
                type: "msg"
                data: "[[;white;]#{@user.name}] has consumed a soul!"

                x: @character.x
                y: @character.y
                realm: @character.realm
                time: now!
              }
              return layout: false, "You have consumed [[;white;]#{name}]'s soul. Your HP is now [[;white;]#{@character.health}]."
            else
              return layout: false, "There are no souls to consume."

          else
            for item in *rawItems
              if ITEM == item.name
                if item.special
                  return layout: false, special\handle command: "take", user: @user, character: @character, item: item
                elseif item.type == "scenery"
                  return layout: false, "You can't take the [[;white;]#{ITEM}]."

                elseif item.type == "item"
                  item\update { character_id: @character.id, realm: "inventory" }
                  Events\create {
                    source_id: @character.id
                    type: "msg"
                    data: "[[;white;]#{@user.name}] picked up a [[;yellow;]#{item.name}]."

                    x: @character.x
                    y: @character.y
                    realm: @character.realm
                    time: now!
                  }
                  return layout: false, "You take the [[;yellow;]#{item.name}]."

            return layout: false, "There is no [[;white;]#{ITEM}] here."

        elseif args[1] == "health" or args[1] == "hp"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          return layout: false, "You have [[;white;]#{@character.health}] HP."

        elseif args[1] == "exits"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          room = Rooms\here @character
          output = "Exits: "
          if room.exits\len! > 0
            if room.exits\find "n"
              output ..= "north, "
            if room.exits\find "w"
              output ..= "west, "
            if room.exits\find "s"
              output ..= "south, "
            if room.exits\find "e"
              output ..= "east, "
            output = output\sub(1, -2).."."
          else
            output ..= "none."
          return layout: false, output

        elseif args[1] == "north" or args[1] == "n"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          room = Rooms\here @character
          if room.exits\find "n"
            @character\update { y: @character.y - 1 }
            return layout: false, false
          else
            return layout: false, "You can't go [[;white;]north]."

        elseif args[1] == "west" or args[1] == "w"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          room = Rooms\here @character
          if room.exits\find "w"
            @character\update { x: @character.x - 1 }
            return layout: false, false
          else
            return layout: false, "You can't go [[;white;]west]."

        elseif args[1] == "south" or args[1] == "s"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          room = Rooms\here @character
          if room.exits\find "s"
            @character\update { y: @character.y + 1 }
            return layout: false, false
          else
            return layout: false, "You can't go [[;white;]south]."

        elseif args[1] == "east" or args[1] == "e"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          room = Rooms\here @character
          if room.exits\find "e"
            @character\update { x: @character.x + 1 }
            return layout: false, false
          else
            return layout: false, "You can't go [[;white;]east]."

        elseif args[1] == "examine" or args[1] == "x"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          unless args[2]
            return layout: false, "[[;red;]Invalid command syntax.]"
          ITEM = table.concat args, " "
          ITEM = ITEM\sub ITEM\find(" ") + 1
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

        elseif args[1] == "power"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"

          -- shitty hack to allow powering local realm with a number
          if #args == 2 and tonumber args[2]
            args[2] = @character.realm
            args[3] = args[2]

          if args[2]
            if realm = Realms\find name: args[2]
              if args[3]
                if count = tonumber(args[3])
                  if @character.health - count > 0
                    realm\update { power: realm.power + count }
                    @character\update { health: @character.health - count }
                    -- Event msg, source me, no target
                    Events\create {
                      source_id: @character.id
                      type: "msg"
                      data: "[[;white;]#{@user.name}] has charged [[;white;]#{realm.name}] by [[;lime;]#{count}]!"

                      x: @character.x
                      y: @character.y
                      realm: @character.realm
                      time: now!
                    }
                    return layout: false, "You have charged [[;white;]#{realm.name}] by [[;lime;]#{count}]!"
                  else
                    return layout: false, "You do not have enough health to power up [[;white;]#{realm.name}] by [[;white;]#{count}]. Collect more [[;yellow;]souls]."
                else
                  return layout: false, "[[;red;]Invalid command syntax.]"
              else
                count = realm\count_characters!
                if realm.power >= 50
                  return layout: false, "[[;white;]#{realm.name}] has [[;lime;]#{realm.power}] power, and is decreasing by [[;red;]#{count}] per minute."
                else
                  return layout: false, "[[;white;]#{realm.name}] has [[;red;]#{realm.power}] power, and is decreasing by [[;red;]#{count}] per minute."
            else
              return layout: false, "[[;white;]#{args[2]}] does not exist."
          else
            realm = Realms\find name: @character.realm
            count = @character\count_in_realm!
            if realm.power >= 50
              return layout: false, "[[;white;]#{realm.name}] has [[;lime;]#{realm.power}] power, and is decreasing by [[;red;]#{count}] per minute."
            else
              return layout: false, "[[;white;]#{realm.name}] has [[;red;]#{realm.power}] power, and is decreasing by [[;red;]#{count}] per minute."

        elseif args[1] == "realms"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          output = ""
          realms = Realms\select "WHERE true"
          for realm in *realms
            if realm.power >= 50
              output ..= " [[;white;]#{realm.name}] ([[;lime;]#{realm.power}]): #{realm.description}\n"
            else
              output ..= " [[;white;]#{realm.name}] ([[;red;]#{realm.power}]): #{realm.description}\n"
          return layout: false, output\sub 1, -1

        elseif args[1] == "enter"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          unless args[2]
            return layout: false, "[[;red;]Invalid command syntax.]"
          if args[2] == "inventory"
            return layout: false, "You cannot enter [[;lime;]inventory]."
          if realm = Realms\find name: args[2]
            if realm.power > 0 or realm.name == "nullspace"
              @character\update { x: 0, y: 0, realm: realm.name }
              return layout: false, "The world around you blinks in and out of existence. You are now in [[;lime;]#{realm.name}]."
            else
              return layout: false, "The world around you blinks once and stays. Seems [[;lime;]#{realm.name}] doesn't have enough [[;white;]power] for you to enter."

        elseif args[1] == "view-report"
          if @user.admin
            if tonumber args[2]
              if report = Events\find id: tonumber args[2]
                if report.type == "report"
                  return layout: false, "[[;orange;]#{report.id}]: #{report.data}"
                elseif report.type == "report-done"
                  return layout: false, "[[;lime;]DONE]: #{report.data}"
              else
                return layout: false, "Report [[;white;]#{args[2]}] doesn't exist or isn't a report event."
            elseif report = Events\find type: "report"
              return layout: false, "[[;orange;]#{report.id}]: #{report.data}"
            else
              return layout: false, "No new reports."

        elseif args[1] == "done"
          if @user.admin
            if args[2]
              if report = Events\find id: tonumber args[2]
                if report.type == "report"
                  report\update { type: "report-done" }
                  return layout: false, "Report [[;white;]#{report.id}] marked done."
                else
                  return layout: false, "Event [[;white;]#{report.id}] is not a report, it is a [[;white;]#{report.type}]."
              else
                return layout: false, "Event [[;white;]#{args[2]}] doesn't exist."
            else
              return layout: false, "[[;red;]You must specify a report ID.]"

        elseif args[1] == "i" or args[1] == "inv" or args[1] == "inventory"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          output = "You are holding "
          inventory = Items\find character_id: @character.id
          if inventory and #inventory > 0
            for item in *inventory
              output ..= "[[;yellow;]#{item.name}], "
            output = output\sub(1, -2).."."
          else
            output ..= "nothing."
          return layout: false, output

        elseif args[1] == "use"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          unless args[2]
            return layout: false, "[[;red;]Invalid command syntax.]"
          ITEM = table.concat args, " "
          ITEM = ITEM\sub ITEM\find(" ") + 1
          inventory = Items\find character_id: @character.id
          for item in *inventory
            if ITEM == item.name
              if item.special
                return layout: false, special\handle command: "use", user: @user, character: @character, item: item
              else
                return layout: false, "You can't use your [[;white;]#{ITEM}]."
          return layout: false, "You don't have a [[;white;]#{ITEM}]."

        elseif args[1] == "drop" or args[1] == "place"
          unless @character.health > 0
            return layout: false, "You are dead. Perhaps you should [[;white;]revive] yourself?"
          unless args[2]
            return layout: false, "[[;red;]Invalid command syntax.]"
          ITEM = table.concat args, " "
          ITEM = ITEM\sub ITEM\find(" ") + 1
          inventory = Items\find character_id: @character.id
          for item in *inventory
            if ITEM == item.name
              item\update { x: @character.x, y: @character.y, realm: @character.realm }
              Events\create {
                source_id: @character.id
                type: "msg"
                data: "[[;white;]#{@user.name}] dropped their [[;yellow;]#{item.name}]."

                x: @character.x
                y: @character.y
                realm: @character.realm
                time: now!
              }
              return layout: false, "You dropped your [[;yellow;]#{item.name}]."

        elseif args[1] == "suicide" -- TEMPORARY COMMAND
          unless @character.health > 0
            return layout: false, "[[;red;]You are already dead.]"
          @character\update { health: 0 }
          Events\create {
            source_id: @character.id
            type: "msg"
            data: "[[;white;]#{@user.name}] mysteriously falls over dead."

            x: @character.x
            y: @character.y
            realm: @character.realm
            time: now!
          }
          return layout: false, "You smehow kill yourself through sheer willpower."

        elseif args[1] == "test" -- testing nesting colors
          return layout: false, "[[;white;]This is [[;red;]a test] of [[;lime;]nesting [[;orange;]colors].]]"


        else
          result = help.skill args
          if result
            return layout: false, result

        -- no else, because some commands can error out (also I used it above)
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
