lapis = require "lapis"

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
        return layout: false, "Here goes nothing! No really, that doesn't work yet."

      elseif @session.id
        @user = Users\find id: @session.id
        return layout: false, "This is a work-in-progress. Nothing happens yet."

      else
        return layout: false, "You must log in first."
  }
