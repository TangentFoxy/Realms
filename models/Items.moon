import Model from require "lapis.db.model"

-- ITEM TYPES:
-- scenery   cannot be picked up, only examined (and punched)
-- item      can be taken
-- soul      can be consumed, that's about it

class Items extends Model
  -- instance method
  tostring: =>
    str = ""
    for key, value in pairs @
      str ..= "#{key} = #{value}\n"
    return str\sub 1, -2


  -- NOTE OLD
  here: (character) =>
    @select "WHERE x = ? AND y = ? AND realm = ?", character.x, character.y, character.realm,
