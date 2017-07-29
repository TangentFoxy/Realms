lapis = require "lapis"
csrf = require "lapis.csrf"

Users = require "models.Users"

class extends lapis.Application
  @path: "/command"

  layout: false

  @before_filter =>
    if @session.id
      @user = Users\find id: @session.id
    else
      return "You must log in."

  [command: ""]: =>
    return "FUCK YEA"
