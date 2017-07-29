import create_table, types from require "lapis.db.schema"

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
}
