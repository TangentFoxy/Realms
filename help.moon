topics = {"user", "interact", "combat", "terminal"}

admin = [[
Admin Commands:

  [[;white;]list] - lists all users, along with their user IDs and email addresses
  [[;white;]online] - lists all users online, along with their coordinates
  [[;white;]whoami] - lists your username, user ID, and email address
  [[;white;]deluser] - deletes a user, WARNING: DOES NOT CONFIRM BEFORE DELETING
]]

user = [[
(Most commands require you to be logged in.)

User Management:

Optional arguments are in brackets. These arguments will be prompted for if you do not specify them.

  [[;white;]create] [user] [email] [password] - creates a user
  [[;white;]login] [user] [password] - logs in as an existing user
  [[;white;]logout] - logs out of a user
  [[;white;]whoami] (OR 'who am i') - prints your username
  [[;white;]rename] name - rename yourself
  [[;white;]chmail] email - change your email address
  [[;white;]chpass] [password] - changes your password
]]

interact = [[
Interaction:

  [[;white;]say] - say something to everyone in the room you are in
  [[;white;]report] - send a message to administrators (reporting a bug, player, an idea - whatever!)
]]

combat = [[
Combat:

  [[;white;]punch] [user] - punch nothing, or a user in the same room as you
  [[;white;]revive] - after you are dead, you can revive at 0,0 in nullspace with 1 HP
]]

terminal = [[
Other Commands:

Optional arguments are in brackets. OR indicates either version works for a command.

  [[;white;]clear] - clears the terminal screen
  [[;white;]help] [page] - prints all help pages or a named page
  [[;white;]history] [-c OR clear] - prints your command history or clears it
  [[;exit;]exit] - logs out of a user, and if your system permits it, closes the page
]]

{
  admin: admin\sub 1, #admin - 1
  user: user\sub 1, #user - 1
  interact: interact\sub 1, #interact - 1
  combat: combat\sub 1, #combat - 1
  terminal: terminal\sub 1, #terminal - 1

  topics: ->
    output = ""
    for name in *topics
      output ..= "  [[;white;]"..name.."]\n"

    return output\sub 1, #output - 1

  build: (is_admin) => -- self should be the correct thing?
    local output
    if is_admin
      output = @admin.."\n\n"
    else
      output = ""

    for name in *topics
      output ..= @[name].."\n\n"

    return output\sub 1, #output - 2
}
