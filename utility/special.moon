db = require "lapis.db"

Items = require "models.Items"

import deepcopy from require "utility.table"

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
        data = deepcopy item
        for key, value in pairs action.duplicate
          data[key] = value

        data.id = nil  -- definitly can't have two with the same id! D:
        data.special = db.NULL
        data.character_id = character.id

        Items\create data
        return "You take the [[;yellow;]#{item.name}], and a few seconds later, another one reappears in its place!"

    return "[[;red;]This is a bug, please use the '][[;white;]report][[;red;]' command (preferrably with a screenshot, or report it on GitHub!) to tell me about this error.]"

  faq_book: {
    duplicate: {
      name: "faq book"
      data: "The F.A.Q. book has nothing in it except a note from the author claiming that no one has asked him enough questions for such a book to be worthy of his time."
      type: "book"
      realm: "inventory"
    }
  }
}

return special
