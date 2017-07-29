lapis = require "lapis"
bcrypt = require "bcrypt"

import respond_to, json_params from require "lapis.application"

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
        if @session.id and user = Users\find id: @session.id
          return layout: false, "You are already logged in, #{user.name}."

      --   if user = Users\find name: @params.name
      --     if bcrypt.verify @params.password, user.digest
      --       @session.id = user.id
      --       return layout: false, "Welcome back, #{user.name}!"

      --   return layout: false, "Invalid username or password."

      elseif @session.id
        @user = Users\find id: @session.id
        return layout: false, "This is a work-in-progress. Nothing happens yet."

      else
        return layout: false, "You must log in first."
  }
