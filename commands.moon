db = require "lapis.db"
bcrypt = require "bcrypt"
config = require("lapis.config").get!

help = require "help"
special = require "special"

Characters = require "models.Characters"
Events = require "models.Events"
Realms = require "models.Realms"
Users = require "models.Users"

import split, alphabetical, remove_duplicates, format_error, report_error from require "utility.string"
import now, recently, timeOut from require "utility.time"

local commands, adminCommands

-- All functions are defined requiring a self,
--  but called using . syntax and passed a Request Object from Lapis as self.

-- Responses are either a string that is to be returned with no layout,
--  a table of a format to be defined containing more instructions,       TODO
--  or false (which means return no message).

adminCommands = {
  deluser: (name) =>
    user = Users\find name: name
    character = user\get_character!
    if character\delete!
      if user\delete!
        return "[[;white;]#{user.name}] deleted."
    return "[[;red;]Failed to delete ][[;white;]#{user.name}][[;red;].]"

  done: (id) =>
    if report = Events\find id: id
      if report.type == "report"
        report\update { type: "report-done" }
        return "Report [[;white;]#{report.id}] marked done."
      elseif report.type == "report-done"
        return "That report is already marked done."
      else
        return format_error "Event #{id} is not a report."
    else
      return format_error "Event #{id} does not exist."

  list: =>
    users = Users\select "WHERE true ORDER BY name ASC"

    output = ""
    for user in *users
      output ..= "[[;white;]#{user.name}] ([[;white;]#{user.id}]) [[;white;]#{user.email}]\n"

    return "#{output}[[;lime;]#{Users\count!}] users"

  mkadmin: (name) =>
    if user = Users\find name: name
      if user\update { admin: true }
        return "[[;white;]#{user.name}] is now an administrator."
      else
        return report_error(@, "error making an administrator", user.name)
    else
      return format_error "There is no user by that name."

  online: =>
    characters = Characters\select "WHERE time >= ?", recently!
    list = {}
    for character in *characters
      table.insert list, {character\get_user!.name, character.x, character.y, character.realm}

    table.sort list, (a, b) -> return a[1] > b[1]
    output = ""
    for user in *list
      output ..= "[[;white;]#{user[1]}] in [[;white;]#{user[4]}] at ([[;white;]#{user[2]}],[[;white;]#{user[3]}])\n"

    return "#{output}[[;lime;]#{#list}] users online"

  ["view-report"]: (id) =>
    local report
    if id
      unless report = Events\find id: tonumber id
        return format_error "There is no event with that ID number."
    else
      unless report = Events\find type: "report"
        return format_error "There are no new reports."

    if report.type == "report"
      return "[[;orange;]#{report.id}]: #{report.data}"
    elseif report.type == "report-done"
      return "[[;orange;]DONE]: #{report.data}"
    else
      return format_error "Event #{id} is not a report."

  whoami: =>
    return "[[;white;]#{@user.name}] ([[;white;]#{@user.id}]) [[;white;]#{@user.email}]"
}

commands = {
  chmail: (email) =>
    if email
      if @user\update { email: email }
        return "Your email is now [[;white;]#{@user.email}]."
      else
        return "That email is in use by another account."
    else
      if @user\update { email: email }
        return "Email has been removed from your account."
      else
        return report_error(@, "error removing email from account")

  chpass: (password) =>
    if password
      if @user\update { digest: bcrypt.digest password, config.digest_rounds }
        return "Your password has been updated."
      else
        return report_error(@, "error updating password", "might be due to not following constraint, report error to user better!")
    else
      if @user\update { digest: db.NULL }
        return "Your password has been removed."
      else
        return report_error(@, "error removing password", "might be due to constraint")

  -- clear: () =>

  create: (name, email, password) =>
    if @user
      return "[[;red;]You are already logged in as ][[;white;]#{@user.name}][[;red;].]"
    else
      local digest
      if password
        digest = bcrypt.digest password, config.digest_rounds
      user, err = Users\create {
        name: name
        email: email
        digest: digest
      }
      if user
        @session.id = user.id
        unless Users\find admin: true
          user\update { admin: true }
        return "Welcome, [[;white;]#{user.name}]!"
      else
        return format_error err

  drop: (itemName) =>
    inventory = @character\get_inventory!
    for item in *inventory
      if itemName == item.name
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
        return "You dropped your [[;yellow;]#{item.name}]."
    return format_error "You do not have a #{itemName}."

  east: =>
    room = @character\get_room!
    if room.exits\find "e"
      @character\update { x: @character.x + 1 }
      return false
    else
      return "You can't go [[;white;]east]."

  enter: (realm) =>
    if realm == "inventory" and not @user.admin
      return "You cannot enter [[;lime;]inventory]."
    else
      if realm = Realms\find name: realm
        if realm.power > 0 or realm.name == "nullspace"
          @character\update { x: 0, y: 0, realm: realm.name }
          return "The world around you blinks in and out of existence. You are now in [[;lime;]#{realm.name}]."
        else
          return "The world around you blinks out of existence and then reappears. Seems [[;lime;]#{realm.name}] doesn't have enough [[;white;]power] for you to enter."
      else
        return format_error "That realm does not exist."

  examine: (target) =>
    t = commands.get_target(@, target)
    return nil

  -- exit: () =>

  exits: =>
    room = @character\get_room!
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
      output = output\sub(1, -3).."."
    else
      output ..= "none."

    return output

  -- internal function, returns table of souls (from the room),
  --  a specific item (from the room or inventory),
  --  or a specific character (from the room)
  get_target: (target) =>
    room = @character\get_room!
    if target == "soul" or target == "souls"
      return room\get_items type: "soul"
    else
      items = room\get_items!
      for item in *items
        if item.name == target
          return item
      inventory = @character\get_inventory!
      for item in *inventory
        if item.name == target
          return item
      characters = room\get_characters!
      for character in *characters
        if character\get_user!.name
          return character

  health: =>
    return "You have [[;white;]#{@character.health}] HP."

  help: (topic) =>
    if topic
      if topic == "topics"
        return help.topics(@user and @user.admin)
      elseif help[topic]
        if (topic != "admin") or (@user and @user.admin)
          return help[topic]
      else
        return "[[;red;]That help topic does not exist.]"
    else
      return help\build(@user and @user.admin)

  -- history: () =>

  inventory: =>
    output = "You are holding "
    if inventory = @character\get_inventory!
      for item in *inventory
        output ..= "[[;yellow;]#{item.name}], "
      output = output\sub(1, -2).."."
    else
      output ..= "nothing."
    return output

  login: (name, password) =>
    if @user
      return "[[;red;]You are already logged in as ][[;white;]#{@user.name}][[;red;].]"
    else
      if user = Users\find name: name
        if bcrypt.verify password, user.digest
          @session.id = user.id
          return "Welcome back, [[;white;]#{user.name}]!"
      return format_error "Invalid username or password."

  logout: =>
    @session.id = nil
    @character\update { time: os.date "!%Y-%m-%d %X", os.time! - (timeOut + 1) } -- set time just before timeOut to leave immediately
    return "Goodbye, [[;white;]#{@user.name}]..."

  look: =>
    room = @character\get_room!
    output = "In [[;lime;]#{room.realm}]:\n#{room.description}"

    items = room\get_items type: "item" -- not scenery, not souls (NOTE might break in the future)
    -- TODO parse and list items

    soulCount = room\get_soul_count!
    -- TODO display

    characters = room\get_characters!
    -- TODO display

    return "#{output}\n\n#{commands.exits(@)}"

  north: =>
    room = @character\get_room!
    if room.exits\find "n"
      @character\update { y: @character.y - 1 }
      return false
    else
      return "You can't go [[;white;]north]."

  online: =>
    return "There are [[;lime;]#{Characters\count "time >= ?", recently!}] users online."

  say: (message) =>
    Events\create {
      source_id: @character.id
      type: "msg"
      data: "[[;white;]#{@user.name}] said, \"#{message}\""
      x: @character.x
      y: @character.y
      realm: @character.realm
      time: now!
    }
    return false

  south: =>
    room = @character\get_room!
    if room.exits\find "s"
      @character\update { y: @character.y + 1 }
      return false
    else
      return "You can't go [[;white;]south]."

  suicide: =>
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
    return "You somehow kill yourself through sheer willpower."

  power: (realm, power) =>
    -- TODO make sure this if statement works
    if realm
      realm = Realms\find name: realm
    else
      realm = Realms\find name: @character.realm
    if realm
      if power
        if @character.health - power > 0
          realm\update { power: realm.power + power }
          @character\update { health: @character.health - power }
          Events\create {
            source_id: @character.id
            type: "msg"
            data: "[[;white;]#{@user.name}] has charged [[;white;]#{realm.name}] by [[;lime;]#{power}]!"
            x: @character.x
            y: @character.y
            realm: @character.realm
            time: now!
          }
          return "You have charged [[;white;]#{realm.name}] by [[;lime;]#{power}]!"
        else
          return "You do not have enough health to charge [[;white;]#{realm.name}] that much. Collect more [[;yellow;]souls]."
      else
        count = realm\get_character_count!
        if realm.power >= 50
          return "[[;white;]#{realm.name}] has [[;lime;]#{realm.power}] power, and is decreasing by [[;red;]#{count}] per minute."
        else
          return "[[;white;]#{realm.name}] has [[;red;]#{realm.power}] power, and is decreasing by [[;red;]#{count}] per minute."
    else
      return format_error "That realm does not exist."

  punch: (target) =>
    if target == "soul" or target == "souls"
      return format_error "You cannot punch the incorporeal."
    t = commands.get_target(@, target)
    return nil

  realms: =>
    output = ""
    realms = Realms\select "WHERE true"
    for realm in *realms
      if realm.power >= 50
        output ..= " [[;white;]#{realm.name}] ([[;lime;]#{realm.power}]): #{realm.description}\n"
      else
        output ..= " [[;white;]#{realm.name}] ([[;red;]#{realm.power}]): #{realm.description}\n"
    return output\sub 1, -2

  rename: (name) =>
    if @user\update { name: name }
      return "You are now [[;white;]#{@user.name}]."
    else
      return format_error "That name is taken."

  report: (message) =>
    if @user
      Events\create {
        source_id: @character.id
        type: "report"
        data: "[[;white;]#{@user.name}]: [[;lime;]#{message}]"
        x: @character.x
        y: @character.y
        realm: @character.realm
        time: now!
      }
    else
      Events\create {
        type: "report"
        data: "[[;lime;]#{message}]"
        time: now!
      }
    return "Your report has been submitted."

  revive: =>
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

          x: @character.x
          y: @character.y
          realm: @character.realm
          time: now!
        }
        return "[[;lime;]You have revived!]"
      else
        return report_error(@, "failed to revive character", "name: [[;white;]#{@character}]")
    else
      return "You are not dead!"

  take: (target) =>
    t = commands.get_target(@, target)

    if target == "soul"
      if t and t[1]
        name = t[1].name
        if @character.souls
          @character\update { health: @character.health + 1, souls: alphabetize remove_duplicates "#{@character.souls} #{name}" }
        else
          @character\update { health: @character.health + 1, souls: name }
        t[1]\delete!
        Events\create {
          source_id: @character.id
          type: "msg"
          data: "[[;white;]#{@user.name}] has consumed a soul!"
          x: @character.x
          y: @character.y
          realm: @character.realm
          time: now!
        }
        return "You have consumed [[;white;]#{name}]'s soul. Your HP is now [[;white;]#{@character.health}]."
      else
        return "There are no souls here."

    elseif target == "souls"
      if t and #t > 1
        room = @character\get_room!
        characters = room\get_character_count!
        soulCount = math.max 2, math.floor #t, characters
        i = 0
        local names
        for soul in *t
          if names
            names ..= " #{soul.data}"
          else
            names = soul.data
          soul\delete!
          i += 1
          if i >= soulCount
            break
        if @character.souls
          @character\update { health: @character.health + soulCount, souls: alphabetize remove_duplicates "#{@character.souls} #{names}" }
        else
          @character\update { health: @character.health + soulCount, souls: alphabetize remove_duplicates names }
        Events\create {
          source_id: @character.id
          type: "msg"
          data: "[[;white;]#{@user.name}] has consumed #{soulCount} souls."
          x: @character.x
          y: @character.y
          realm: @character.realm
          time: now!
        }
        return "You have consumed [[;white;]#{soulCount}] souls. Your HP is now [[;white;]#{@character.health}]."
      else
        return commands.take(@, "soul")

    elseif t -- item or character
      if t.health -- is a character
        return "You can't take a person."
      elseif t.special -- item with special case
        return special\handle(@, command: "take", item: t) -- TODO
      elseif t.type == "scenery"
        return "You can't take the [[;white;]#{t.name}]."
      elseif t.type == "item"
        t\update { character_id: @character.id, realm: "inventory" }
        Events\create {
          source_id: @character.id
          type: "msg"
          data: "[[;white;]#{@user.name}] picked up a [[;yellow;]#{t.name}]."
          x: @character.x
          y: @character.y
          realm: @character.realm
          time: now!
        }
        return "You take the [[;yellow;]#{t.name}]."
      else
        return report_error(@, "invalid t.type '#{t.type}'", "#{t\tostring!}")
    else
      return "There is no [[;yellow;]#{target}] here."

  use: (itemName) =>
    inventory = @character\get_inventory!
    for item in *inventory
      if itemName == item.name
        if item.special
          return special\handle(@, command: "use", item: item) -- TODO
        else
          return format_error "You can't use your #{item.name}."
    return format_error "You don't have a #{itemName}."

  west: =>
    room = @character\get_room!
    if room.exits\find "w"
      @character\update { x: @character.x - 1 }
      return false
    else
      return "You can't go [[;white;]west]."

  whoami: =>
    return "You are [[;white;]#{@user.name}]."
}

-- arg.required    defaults to true
-- command.user    defaults to true
-- command.admin   defaults to false
--                  if true, command.alive defaults to false
-- command.alive   defaults to true

parseTable = {
  chmail: {
    args: {
      { name: "email", type: "string", required: false }
    }
    alive: false
  }

  chpass: {
    args: {
      { name: "password", type: "string", required: false }
    }
    alive: false
  }

  -- clear: {}

  create: {
    args: {
      { name: "name", type: "string" }
      { name: "email", type: "string", required: false }
      { name: "password", type: "string", required: false }
    }
    user: false
  }

  deluser: {
    args: {
      { name: "name", type: "string" }
    }
    admin: true
  }

  done: {
    args: {
      { name: "id", type: "number" }
    }
    admin: true
  }

  drop: {
    args: {
      { name: "item", type: "long string" }
    }
  }

  east: {
    args: {}
  }

  enter: {
    args: { name: "realm", type: "string" }
  }

  examine: {
    args: { name: "target", type: "long string" } -- TODO make user examineable
  }

  -- exit: {}

  exits: {
    args: {}
  }

  health: {
    args: {}
  }

  help: {
    args: {
      { name: "topic", type: "string", required: false }
    }
    user: false
    alive: false
  }

  -- history: {}

  inventory: {
    args: {}
  }

  list: {
    args: {}
    admin: true
  }

  login: {
    args: {
      { name: "name", type: "string" }
      { name: "password", type: "string", required: false }
    }
    user: false
  }

  logout: {
    args: {}
    alive: false
  }

  look: {
    args: {}
  }

  mkadmin: {
    args: {
      { name: "name", type: "string" }
    }
    admin: true
  }

  north: {
    args: {}
  }

  online: {
    args: {}
    alive: false
  }

  say: {
    args: {
      { name: "message", type: "long string" }
    }
  }

  south: {
    args: {}
  }

  suicide: {
    args: {}
  }

  power: { -- TODO charge alias
    args: {
      { name: "realm", type: "string", required: false }
      { name: "power", type: "number", required: false }
    }
  }

  punch: {
    args: {
      { name: "target", type: "long string" }
    }
  }

  realms: {
    args: {}
  }

  rename: {
    args: {
      { name: "name", type: "string" }
    }
    alive: false
  }

  report: {
    args: {
      { name: "message", type: "long string" }
    }
    alive: false
  }

  revive: {
    args: {}
    alive: false
  }

  take: {
    args: {
      { name: "target", type: "long string" }
    }
  }

  ["view-report"]: {
    args: {
      { name: "id", type: "number", required: false }
    }
    admin: true
  }

  use: {
    args: {
      { name: "item", type: "long string" }
    }
  }

  west: {
    args: {}
  }

  whoami: {
    args: {}
    alive: false
  }
}

-- setting defaults
for command in *parseTable
  for arg in *command.args
    if arg.required == nil
      arg.required = true
  if command.user == nil
    command.user = true
  if command.admin == nil
    command.admin = false
  if command.alive == nil
    if command.admin
      command.alive = false
    else
      command.alive = true


parseCommand = (input) =>
  input = split input
  commandName = input[1]
  arguments = {}

  if command = parseTable[commandName]
    if command.user
      unless @user
        return format_error "You must be logged in."
      if command.admin
        unless @user.admin
          return format_error "You do not have permission to execute this command."
      if command.alive
        unless @character.health > 0
          return format_error "You are dead."

    table.remove input, 1 -- remove the command itself from its arguments
    for arg in *command.args
      if arg.type == "long string"
        str = table.concat input, " "
        if str\len! > 0
          table.insert arguments, str
          break -- we are done parsing arguments at the first long string
        elseif arg.required
          return "[[;white;]#{commandName}][[;red;] requires ][[;white;]#{arg.name}][[;red;].]"
        else
          table.insert arguments, false

      elseif arg.type == "string"
        if input[1] and input[1]\len! > 0
          table.insert arguments, input[1]
          table.remove input, 1
        elseif arg.required
          return "[[;white;]#{commandName}][[;red;] requires ][[;white;]#{arg.name}][[;red;].]"
        else
          table.insert arguments, false

      elseif arg.type == "number"
        value = tonumber input[1]
        if value
          table.insert arguments, value
          table.remove input, 1
        elseif arg.required
          return "[[;white;]#{commandName}][[;red;] requires ][[;white;]#{arg.name}][[;red;].]"
        else
          table.insert arguments, false

      else
        return report_error(@, "invalid arg.type '#{arg.type}'", commandName)

    if command.admin or (@user and @user.admin)
      if adminCommands[commandName]
        return adminCommands[commandName](@, unpack arguments)
      elseif commands[commandName]
        return commands[commandName](@, unpack arguments)
    else
      if commands[commandName]
        return commands[commandName](@, unpack arguments)
      else
        return report_error(@, "invalid command in parseTable", commandName)

  else
    return format_error "Invalid command."

{
  :parseCommand
}
