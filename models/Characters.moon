import Model from require "lapis.db.model"

local Characters

class Characters extends Model
  @relations: {
    {"user", belongs_to: "Users"}
  }

  here: =>
    Characters\select "WHERE x = ? AND y = ? AND realm = ? AND time >= ?", @x, @y, @realm, os.date "!%Y-%m-%d %X", os.time! - timeOut
