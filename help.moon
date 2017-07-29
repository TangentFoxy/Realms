admin = [[
Admin Commands:

  [[;white;]list] - lists all users, along with their user IDs and email addresses
  [[;white;]whoami] - lists your username, user ID, and email address
]]

user = [[
User Management:

Optional arguments are in brackets. These arguments will be prompted for if you do not specify them.

  [[;white;]create] [user] [email] [password] - creates a user
  [[;white;]login] [user] [password] - logs in as an existing user
  [[;white;]logout] - logs out of a user
  [[;white;]whoami] - prints your username
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
  terminal: terminal\sub 1, #terminal - 1

  build: (is_admin) => -- self should be the correct thing?
    local output
    if is_admin
      output = @admin.."\n\n"
    else
      output = ""

    output ..= @user.."\n\n"..@terminal

    return output
}
