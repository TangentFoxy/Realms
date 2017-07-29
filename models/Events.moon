import Model from require "lapis.db.model"
import timeOut from require "utility.numbers"

-- EVENT TYPES:
-- msg      The result of someone using `say` or `tell`.
-- punch    Acts like a `msg`, sent to local players.
-- report   Sent to any online admins wherever they are.

class Events extends Model
  @relations: {
    {"source", belongs_to: "Characters", key: "source_id"}
    {"target", belongs_to: "Characters", key: "target_id"}
  }

  here: (character) =>
    @select "WHERE x = ? AND y = ? AND realm = ? AND time >= ?", character.x, character.y, character.realm, os.date "!%Y-%m-%d %X", os.time! - timeOut

  now: =>
    @select "WHERE time >= ?", os.date "!%Y-%m-%d %X", os.time! - timeOut
