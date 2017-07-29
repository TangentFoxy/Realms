import Model from require "lapis.db.model"
import timeOut from require "utility.numbers"

local Characters

class Characters extends Model
  @relations: {
    {"user", belongs_to: "Users"}
  }

  here: =>
    return Characters\select "WHERE x = ? AND y = ? AND realm = ? AND time >= ?", @x, @y, @realm, os.date "!%Y-%m-%d %X", os.time! - timeOut
