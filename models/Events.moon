import Model from require "lapis.db.model"
import now, recently from require "utility.time"
-- cannot import from utility.string!!

-- EVENT TYPES:
-- msg           The result of someone using `say` or `tell`.
-- punch         Acts like a `msg`, sent to local players.
-- report        Sent to any online admins wherever they are.
-- report-done   A report marked as done.

class Events extends Model
  @relations: {
    {"source", belongs_to: "Characters", key: "source_id"}
    {"target", belongs_to: "Characters", key: "target_id"}
  }



  -- NOTE BELOW HERE ARE OLD DEFINITIONS --
  now: =>
    @select "WHERE time >= ?", recently!

  targeted: (character) =>
    @select "WHERE target_id = ? AND time >= ?", character, recently!

  targeted_not_here: (character) =>
    @select "WHERE NOT x = ? AND NOT y = ? AND target_id = ? AND time >= ?", character.x, character.y, character.id, recently!
