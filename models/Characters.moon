import Model from require "lapis.db.model"

class Characters extends Model
  @relations: {
    {"user", belongs_to: "Users"}
  }
