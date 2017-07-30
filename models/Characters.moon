import Model from require "lapis.db.model"
import timeOut, recently from require "utility.time"

local Characters

class Characters extends Model
  @relations: {
    {"user", belongs_to: "Users"}
  }

  here: =>
    Characters\select "WHERE x = ? AND y = ? AND realm = ? AND time >= ?", @x, @y, @realm, os.date "!%Y-%m-%d %X", os.time! - timeOut

  count_in_realm: =>
    Characters\count "realm = ? AND time >= ?", @realm, recently!

  in_realm: =>
    Characters\select "WHERE realm = ? AND time >= ?", @realm, recently!
