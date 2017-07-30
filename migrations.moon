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

      {"x", types.integer default: 0}
      {"y", types.integer default: 0}
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
      {"source_id", types.foreign_key null: true}
      {"target_id", types.foreign_key null: true}
      {"type", types.text}   -- TODO if I refactor / care, convert this to a varchar
      {"data", types.text}

      {"x", types.integer default: 0}
      {"y", types.integer default: 0}
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
}
