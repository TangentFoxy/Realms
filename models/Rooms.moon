import Model from require "lapis.db.model"

class Rooms extends Model
  here: (character) =>
    @find x: character.x, y: character.y, realm: character.realm
