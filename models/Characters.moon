import Model from require "lapis.db.model"
import timeOut, recently from require "utility.time"

local Characters, Events, Items, Rooms

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

  -- instance method
  get_events: =>
    unless Events
      Events = require "models.Events"
    Events\select "WHERE x = ? AND y = ? AND realm = ? AND time >= ? AND NOT type = ? AND NOT type = ? AND NOT source_id = ?", @x, @y, @realm, recently!, "report", "report-done", @id

  -- instance method
  get_targeted_events: =>
    unless Events
      Events = require "models.Events"
    Events\select "WHERE NOT x = ? AND NOT y = ? AND target_id = ? AND time >= ?", @x, @y, @id, recently!




  -- NOTE these are old
  count_in_realm: =>
    Characters\count "realm = ? AND time >= ?", @realm, recently!

  in_realm: =>
    Characters\select "WHERE realm = ? AND time >= ?", @realm, recently!
