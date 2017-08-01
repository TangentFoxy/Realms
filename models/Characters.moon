import Model from require "lapis.db.model"
import timeOut, recently from require "utility.time"

local Characters, Items, Rooms

class Characters extends Model
  @relations: {
    {"user", belongs_to: "Users"}
  }

  -- instance method
  get_room: =>
    unless Rooms
      Rooms = require "models.Rooms"
    -- TODO if in inventory realm, return a fake Room object
    Rooms\find x: @character.x, y: @character.y, realm: @character.realm

  -- instance method
  get_inventory: =>
    unless Items
      Items = require "models.Items"
    Items\select "WHERE character_id = ?", @character.id


  -- NOTE these are old
  here: =>
    Characters\select "WHERE x = ? AND y = ? AND realm = ? AND time >= ?", @x, @y, @realm, os.date "!%Y-%m-%d %X", os.time! - timeOut

  count_in_realm: =>
    Characters\count "realm = ? AND time >= ?", @realm, recently!

  in_realm: =>
    Characters\select "WHERE realm = ? AND time >= ?", @realm, recently!
