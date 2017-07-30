-- import deepcopy from require "utility.table"

local special

special = {
  handle: (o) =>
    command = o.command
    user = o.user
    character = o.character
    item = o.item

    -- needs to return a string to return to the user, otherwise it needs to do things itself, like setting Events
    if command == "take"
      action = special[item.special]
      if action.duplicate
        str = ""
        for k,v in pairs(item)
          str ..="#{k}=#{v}\n"
        return str
        -- data = deepcopy duplicate
        -- Items\create duplicate
    return "FUCKD UP"

    -- Items\create {
    --   name: "book"
    --   type: "scenery"
    --   data: "It says F.A.Q. on it."
    --   realm: "nullspace"
    --   special: "faq_book"
    -- }

    -- create_table "items", {
    --   {"id", types.serial primary_key: true}
    --   {"character_id", types.foreign_key null: true}
    --   {"type", types.varchar}
    --   {"data", types.text}
    --
    --   {"x", types.integer default: 0}
    --   {"y", types.integer default: 0}
    --   {"realm", types.varchar default: "inventory"}   -- inventory is a special realm that means a character has it
    -- }

  faq_book: {
    duplicate: {
      name: "faq book"
      data: "The F.A.Q. book has nothing in it except a note from the author claiming that no one has asked him enough questions for such a book to be worthy of his time."
      type: "book"
    }
  }
}

return special
