import Model from require "lapis.db.model"
import recently from require "utility.time"

local Characters

class Realms extends Model
  -- instance method
  get_character_count: =>
    unless Characters
      Characters = require "models.Characters"
    Characters\count "realm = ? AND time = ?", @name, recently!


  -- NOTE old
  count_characters: =>
    Characters\count "realm = ? AND time >= ?", @name, recently!

  get_characters: =>
    Characters\select "WHERE realm = ?", @name
