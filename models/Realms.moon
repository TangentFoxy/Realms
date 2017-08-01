import Model from require "lapis.db.model"
import recently from require "utility.time"

local Characters

class Realms extends Model
  -- instance method
  get_characters: =>
    unless Characters
      Characters = require "models.Characters"
    Characters\select "WHERE realm = ? AND time >= ?", @name, recently!

  -- instance method
  get_character_count: =>
    unless Characters
      Characters = require "models.Characters"
    Characters\count "realm = ? AND time >= ?", @name, recently!
