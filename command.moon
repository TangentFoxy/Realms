lapis = require "lapis"
bcrypt = require "bcrypt"
config = require("lapis.config").get!

import respond_to, json_params from require "lapis.application"
import split from require "utility.string"

Users = require "models.Users"

class extends lapis.Application
  @path: "/command"

  [command: ""]: respond_to {
    GET: =>
      return layout: false, status: 405, "Method not allowed."

    POST: json_params =>
      if @params.command == "help"
        return layout: false, "Help text would go here, if I was a better programmer."

      elseif @params.command == "login"
        if @session.id
          if user = Users\find id: @session.id
            return layout: false, "You are already logged in, #{user.name}."
          -- else
          --   @session.id = nil
          --   return layout: false, "You were somehow logged into a non-existant account..."

        if user = Users\find name: @params.name
          if bcrypt.verify @params.password, user.digest
            @session.id = user.id
            return layout: false, "Welcome back, #{user.name}!"

        return layout: false, "Invalid username or password."

      elseif @params.command == "create"
        if @session.id
          if user = Users\find id: @session.id
            return layout: false, "You are already logged in as #{user.name}!"

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
          return layout: false, errMsg

      elseif @session.id
        @user = Users\find id: @session.id

        args = split @params.command

        if args[1] == "logout"
          @session.id = nil
          return layout: false, "Goodbye, #{@user.name}..."

        elseif args[1] == "whoami"
          return layout: false, "You are #{@user.name}."

        elseif args[1] == "list"
          if @user.admin
            users = Users\select "WHERE true ORDER BY name ASC"

            out = ""
            for user in *users
              out ..= "#{user.name} (#{user.id}) #{user.email}"

            out ..= "#{Users\count!} users."

            return layout: false, out


        -- no else, because some commands can error out
        return layout: false, "[[;red;]Invalid command.]"

      else
        return layout: false, "You must log in first."
  }
