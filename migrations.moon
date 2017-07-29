db = require "lapis.db"

import create_table, types, add_column from require "lapis.db.schema"

Characters = require "models.Characters"

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

    users = Users\select "WHERE true"
    for user in *users
      Characters\create { user_id: user.id }

  [3]: =>
    add_column "characters", "health", types.integer default: 1
    db.update "characters", {
      health: 1 -- what to do
    }, "true" -- WHERE true

  [4]: =>
    add_column "characters", "souls", types.text null: true
}
