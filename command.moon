version = 5   -- alert user to update their client by refreshing

lapis = require "lapis"
bcrypt = require "bcrypt"
help = require "help"
config = require("lapis.config").get!

import respond_to, json_params from require "lapis.application"
import split from require "utility.string"

Users = require "models.Users"
Characters = require "models.Characters"

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
        if args[2] and help[args[2]]
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
        if @params.password
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

      elseif @session.id
        @user = Users\find id: @session.id

        if args[1] == "logout"
          @session.id = nil
          return layout: false, "Goodbye, #{@user.name}..."

        elseif args[1] == "whoami"
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
        Characters\create { user_id: @user.id }

      @character\update { time: os.date "!%Y-%m-%d %X" } -- we are here now

      -- get everyone who was here in the past 60 seconds
      rawCharacters = Characters\select "WHERE x = ? AND y = ? AND time >= ?", @character.x, @character.y, os.date "!%Y-%m-%d %X", os.time! - 60
      characters = {}
      for character in *rawCharacters
        user = character\get_user!
        table.insert characters, user.name

    else
      return json: { :characters }
