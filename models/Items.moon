import Model from require "lapis.db.model"

class Items extends Model
  here: (character) =>
    @select "WHERE x = ? AND y = ? AND realm = ?", character.x, character.y, character.realm,
