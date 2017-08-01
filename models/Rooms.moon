import Model from require "lapis.db.model"
import recently from require "utility.time"

local Characters, Items

class Rooms extends Model
  -- instance method
  get_items: (opts={}) =>
    unless Items
      Items = require "models.Items"
    if opts.type
      return Items\select "WHERE x = ? AND y = ? AND realm = ? AND type = ?" @x, @y, @realm, opts.type
    else
      return Items\select "WHERE x = ? AND y = ? AND realm = ? AND NOT type = ?" @x, @y, @realm, "soul"

  -- instance method
  get_soul_count: =>
    unless Items
      Items = require "models.Items"
    return Items\count "x = ? AND y = ? AND realm = ? AND type = ?", @x, @y, @realm, "soul"

  -- instance method
  get_characters: =>
    unless Characters
      Characters = require "models.Characters"
    Characters\select "WHERE x = ? AND y = ? AND realm = ? AND time = ?" @x, @y, @realm, recently!

  -- instance method
  get_character_count: =>
    unless Characters
      Characters = require "models.Characters"
    Characters\count "x = ? AND y = ? AND realm = ? AND time = ?", @x, @y, @realm, recently!


  --NOTE OLD
  here: (character) =>
    @find x: character.x, y: character.y, realm: character.realm
