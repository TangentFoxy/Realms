lapis = require "lapis"
config = require("lapis.config").get!

class GithookApp extends lapis.Application
  [githook: "/githook"]: =>
    result = "#{os.execute "git pull origin"}"
    result ..= "\n\n" .. "#{os.execute "git submodule init"}"     -- not gonna use submodules ?
    result ..= "\n\n" .. "#{os.execute "git submodule update"}"   -- not gonna use submodules ?
    result ..= "\n\n" .. "#{os.execute "moonc ."}"
    result ..= "\n\n" .. "#{os.execute "lapis migrate #{config._name}"}"
    result ..= "\n\n" .. "#{os.execute "lapis build #{config._name}"}"
    return { json: { data: result } }
