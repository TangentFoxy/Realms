lapis = require "lapis"
config = require("lapis.config").get!

class GithookApp extends lapis.Application
  [githook: "/githook"]: =>
    failed = "failed"
    result = {}
    result.pull = os.execute("git pull origin") or failed
    result.submodule_init = os.execute("git submodule init") or failed
    result.submodule_update = os.execute("git submodule update") or failed
    result.compile = os.execute("moonc .") or failed
    result.migration = os.execute("lapis migrate #{config._name}") or failed
    result.rebuild = os.execute("lapis build #{config._name}") or failed
    return { json: { data: result } }
