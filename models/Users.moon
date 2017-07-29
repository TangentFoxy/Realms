import Model from require "lapis.db.model"
import trim from require "lapis.util"

class Users extends Model
  @constraints: {
    name: (value) =>
      if not value
        return "You must enter a username."

      value = trim value

      if value\find "%W"
        return "Usernames can only contain alphanumeric characters."

      if Users\find name: value
        return "That username is already taken."

      lower = value\lower!
      if (lower == "admin") or (lower == "administrator") or (lower == "new") or (lower == "edit") or (lower == "create") or (lower == "login") or (lower == "logout") or (lower == "me")
        return "That username is already taken."

    email: (value) =>
      if value
        value = trim value

      -- TODO figure out how to check for valid email address

      if Users\find email: value
        return "That email address is already tied to an account."
  }

  @relations: {
    {"character", has_one: "Characters"}
  }
