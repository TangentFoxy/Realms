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
    Rooms\find x: @x, y: @y, realm: @realm

  -- instance method
  get_inventory: =>
    unless Items
      Items = require "models.Items"
    Items\select "WHERE character_id = ?", @id




  -- NOTE these are old
  count_in_realm: =>
    Characters\count "realm = ? AND time >= ?", @realm, recently!

  in_realm: =>
    Characters\select "WHERE realm = ? AND time >= ?", @realm, recently!
