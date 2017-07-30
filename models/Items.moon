import Model from require "lapis.db.model"

-- ITEM TYPES:
-- scenery   cannot be picked up, only examined (and punched)
-- item      can be taken
-- soul      can be consumed, that's about it

class Items extends Model
  here: (character) =>
    @select "WHERE x = ? AND y = ? AND realm = ?", character.x, character.y, character.realm,
