local special

special = {
  handle: (opts) =>
    -- opts.user, opts.character, opts.command, opts.item (which has the key)
    -- TODO
    -- needs to return a string to return to the user, otherwise it needs to do things itself, like setting Events

  faq_book: {
    duplicate: {
      name: "faq book"
      data: "The F.A.Q. book has nothing in it except a note from the author claiming that no one has asked him enough questions for such a book to be worthy of his time."
    }
  }
}

return special
