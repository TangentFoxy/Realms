import Model from require "lapis.db.model"
import recently from require "utility.time"

Characters = require "models.Characters"

class Realms extends Model
  count_characters: =>
    Characters\count "realm = ? AND time >= ?", @name, recently!

  get_characters: =>
    Characters\select "WHERE realm = ?", @name
