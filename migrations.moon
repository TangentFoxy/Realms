db = require "lapis.db"

import create_table, types, add_column from require "lapis.db.schema"

Characters = require "models.Characters"
Rooms = require "models.Rooms"
Realms = require "models.Realms"
Items = require "models.Items"

{
  [1]: =>
    create_table "users", {
      {"id", types.serial primary_key: true}
      {"name", types.varchar unique: true}
      {"email", types.text null: true}
      {"digest", types.text null: true}
      {"admin", types.boolean default: false}
    }

  [2]: =>
    create_table "characters", {
      {"id", types.serial primary_key: true}
      {"user_id", types.foreign_key unique: true}
      -- {"health", types.integer default: 1}
      -- {"souls", types.text null: true}

      {"x", types.integer default: 0}
      {"y", types.integer default: 0}
      -- {"realm", types.varchar default: "nullspace"}

      {"time", types.time default: "1970-01-01 00:00:00"} -- assume they've never been on by default
    }

    -- this errored for some reason
    -- users = Users\select "WHERE true"
    -- for user in *users
    --   Characters\create { user_id: user.id }

  [3]: =>
    add_column "characters", "health", types.integer default: 1
    db.update "characters", {
      health: 1 -- what to do
    }, "true" -- WHERE true

  [4]: =>
    add_column "characters", "souls", types.text null: true

  [5]: =>
    create_table "events", {
      {"id", types.serial primary_key: true}
      {"source_id", types.foreign_key null: true} -- these are character IDs
      {"target_id", types.foreign_key null: true} -- these are character IDs
      {"type", types.text}   -- TODO if I refactor / care, convert this to a varchar
      {"data", types.text}

      {"x", types.integer default: 0}
      {"y", types.integer default: 0}
      -- {"realm", types.varchar default: "nullspace"}

      {"time", types.time default: "1970-01-01 00:00:00"}
    }

  [6]: =>
    add_column "characters", "realm", types.varchar default: "nullspace"
    add_column "events", "realm", types.varchar default: "nullspace"
    db.update "characters", {
      realm: "nullspace"
    }, "true"
    db.update "events", {
      realm: "nullspace"
    }, "true"

  [7]: =>
    create_table "items", {
      {"id", types.serial primary_key: true}
      {"character_id", types.foreign_key null: true}

      {"type", types.varchar}
      {"data", types.text}
      -- {"name", types.varchar null: true}
      -- {"special", types.text null: true}

      {"x", types.integer default: 0}
      {"y", types.integer default: 0}
      {"realm", types.varchar default: "inventory"}   -- inventory is a special realm that means a character has it
    }

  [8]: =>
    create_table "rooms", {
      {"id", types.serial primary_key: true}
      {"description", types.text default: "There is nothing remarkable about this room. :("}
      {"exits", types.varchar default: ""}

      {"x", types.integer default: 0}
      {"y", types.integer default: 0}
      {"realm", types.varchar default: "nullspace"}
    }

    create_table "realms", {
      {"id", types.serial primary_key: true}
      {"name", types.varchar}
      {"description", types.text}

      {"power", types.integer default: 100}
    }

    add_column "items", "name", types.varchar null: true

    -- this one basically exists
    Rooms\create {
      description: "There is a large [[;yellow;]corkboard] in front of you. On a [[;yellow;]table] next to it lies a green [[;yellow;]book]."
      x: 0
      y: 0
      realm: "nullspace"
    }

    Items\create {
      name: "corkboard"
      type: "scenery"
      data: "It is completely empty."
      realm: "nullspace"
    }

    Items\create {
      name: "table"
      type: "scenery"
      data: "An unremarkable wooden endtable."
      realm: "nullspace"
    }

    Items\create {
      name: "book"
      type: "scenery"
      data: "It says F.A.Q. on it."
      realm: "nullspace"
    }

    Realms\create {
      name: "nullspace"
      description: "The void from whence we came, and return to."
    }

  [9]: =>
    add_column "items", "special", types.text null: true
    book = Items\find name: "book"
    book\update { special: "faq_book" }  -- special is a key that goes to a list of special functions specific to particular items

  [10]: =>
    Realms\create {
      name: "inventory"
      description: "A strange place with items haphazardly placed in dark rooms."
    }

  [11]: =>
    Realms\create {
      name: "userland"
      description: "The chaotic stream of consciousness fromed by the denizens who enter."
    }
    Realms\create {
      name: "eventstack"
      description: "Echoes, forgotten notes, an ongoing din of whitenoise."
    }
    Rooms\create {
      description: "The room is blindingly white. A [[;yellow;]projector] is aimed at the north wall. It flickers between \"Welcome to [[;pink;]userland]!\" and \"Enjoy [[;white;]make]-ing your creations. Don't forget to [[;white;]report] ideas.\""
      realm: "userland"
    }
    Items\create {
      name: "projector"
      type: "scenery"
      data: "It is white and smooth, with the word \"Blusmart\" written on it. There is a picture of a remote drawn on it in black marker."
      realm: "userland"
    }
    Items\create {
      name: "sticky notes"
      type: "item"
      data: "A small pad of yellow sticky notes with attached pencil."
      realm: "userland"
      special: "sticky_notes"
    }
    room = Rooms\find x: 0, y: 0, realm: "nullspace"
    room\update {
      description: "You stand in a black void. It is difficult to see your own feet. However, you can clearly see a large [[;yellow;]corkboard] in front of you, and on a [[;yellow;]table] next to it lies a green [[;yellow;]book]."
    }
    -- eventstack doesn't have room
    -- inventory doesn't have room either

  [12]: =>
    Rooms\create {
      description: "An empty room that looks like it once belonged to a hospital. There is a [[;yellow;]filing cabinet] in the center."
      realm: "eventstack"
    }
    Items\create {
      name: "filing cabinet"
      type: "scenery"
      data: "A dull gray color. You can't seem to get any drawers open."
      realm: "eventstack"
    }
    -- inventory still doesn't have a room, and won't, they are generated on the fly (and aren't actually rooms)

  [13]: =>
    Items\create {
      name: "dummy"
      type: "scenery"
      data: "A wooden dummy, designed for practising combat techniques."
      realm: "nullspace"
    }

  [14]: =>
    item = Items\find name: "dummy"
    item\update { special: "soul_dummy" }
    room = Rooms\find x: 0, y: 0, realm: "nullspace"
    room\update {
      description: "You stand in a black void. It is difficult to see your own feet. However, you can clearly see a large [[;yellow;]corkboard] in front of you, and on a [[;yellow;]table] next to it lies a green [[;yellow;]book]. Off to the side, there is a wooden [[;yellow;]dummy]."
    }

  [15]: =>
    characters = Characters\select "WHERE true"
    for character in *characters
      if not character\get_user!
        character\delete!

  [16]: =>
    room = Rooms\find x: 0, y: 0, realm: "nullspace"
    room\update { exits: "s" }
    Rooms\create {
      description: "A rocky room with no visible exits."
      x: 0
      y: 1
      realm: "nullspace"
    }
    Items\create {
      name: "hammer"
      type: "item"
      data: "A ballpeen hammer."
      x: 0
      y: 1
      realm: "nullspace"
    }
    Items\create {
      name: "broken pencil"
      type: "item"
      data: "A pencil that has been thoroughly chewed and broken partially in the middle. The graphite is missing."
      x: 0
      y: 1
      realm: "nullspace"
    }

}
