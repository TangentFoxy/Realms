var commandUrl = "https://ld39.guard13007.com/command";
var version = 27; // internal version number indicating only changes on client-side requiring a user to refresh their page
var timeOut = 30;

var Terminal;
var History;
var Self = {}; // defined by first update() call
var Characters = {};
var Events = {};

function update(first) {
  $.post(commandUrl + "/update", {version: version}, function(data, status) {
    if (status == "success") {
      console.log(data);

      if (typeof(data) == "string") {
        Terminal.echo("[[b;pink;]SERVER ERROR]: [[;red;]" + data.slice(1, data.indexOf("\n") - 1) + "]", {keepWords: true});
      } else if (data.echo) {
        Terminal.echo(data.echo, {keepWords: true});
      }

      var justEntered = false;

      if (data.you) {
        if (!Self.name) {
          if (first) {
            Terminal.echo("Welcome back, " + data.you.name + "!", {keepWords: true});
          }
          justEntered = true;
        }
        Self = data.you;
      }

      if (data.characters) {
        for (var character in data.characters) {
          if (!Characters[character]) {
            if (character != Self.name) {
              if (justEntered) {
                if (data.characters[character].health == 0) {
                  Terminal.echo("[[;white;]" + character + "]'s corpse is here.", {keepWords: true});
                } else {
                  Terminal.echo("[[;white;]" + character + "] is here.", {keepWords: true});
                }
              } else {
                Terminal.echo("[[;white;]" + character + "] enters.", {keepWords: true});
              }
            }
            Characters[character] = character;
          }
        }
        for (var character in Characters) {
          if (!data.characters[character]) {
            if (character == Self.name) {
              Terminal.echo("[[;red;]Somehow, you have left. Please refresh the page.]", {keepWords: true});
            } else {
              Terminal.echo("[[;white;]" + character + "] has left.", {keepWords: true});
            }
            delete Characters[character];
          }
        }
      }

      if (data.events) {
        for (var i = 0; i < data.events.length; i++) {
          var event = data.events[i];
          if (!Events[event.id]) {
            Events[event.id] = event;
          }
        }
      }

      var now = Math.floor(Date.now() / 1000);
      for (var e in Events) {
        var event = Events[e];
        if (!event.done) {
          if (event.targeted && event.type == "punch") {
            Terminal.echo("[[;white;]" + event.source + "] punched you!", {keepWords: true});
            if (Self.health <= 0) {
              Terminal.echo("[[;red;]You are dead.]", {keepWords: true});
            }
          } else if (event.type == "report") {
            Terminal.echo("[[;pink;]" + event.id + "]: " + event.msg, {keepWords: true});
          } else {
            Terminal.echo(event.msg, {keepWords: true});
          }
          event.done = true;
        }
        if (event.time < (now - timeOut * 2)) {
          delete Events[e];
        }
      }

    } else {
      Terminal.echo("[[b;pink;]Connection/Server error]: " + status, {keepWords: true});
    }
  })

  setTimeout(update, 1000);
}

$(function() {
  $('#terminal').terminal(function(command, term) {
    if (command == "") { return false; }

    var args = command.split(" ");

    if (args[0] == "exit") {
      Terminal.pause();
      $.post(commandUrl, {command: "logout", version: version}).then(function(response) {
        Terminal.echo(response, {keepWords: true});
      });
      window.close(); // may or may not be permitted by the browser

    } else if (args[0] == "login") {
      var user, password;

      if (args[2]) {
        var data = History.data();
        data.pop();
        History.set(data);
        Terminal.pause();
        $.post(commandUrl, {command: "login", name: args[1], password: args[2], version: version}).then(function(response) {
          if (response.indexOf("Welcome back, ") == 0) {
            Self = args[1];
          }
          Terminal.echo(response, {keepWords: true}).resume();
        });
      } else {
        Terminal.push(function(c) {
          password = c;
          Terminal.pop();
          History.enable();

          Terminal.pause();
          $.post(commandUrl, {command: "login", name: user, password: password, version: version}).then(function(response) {
            if (response.indexOf("Welcome back, ") == 0) {
              Self = user;
            }
            Terminal.echo(response, {keepWords: true}).resume();
          });
        }, {
          prompt: "Password: ",
          onStart: function() {
            Terminal.set_mask(true);
            History.disable();
          }
        });
      }

      if (args[1]) {
        user = args[1];
      } else {
        Terminal.push(function(c) {
          user = c;
          Terminal.pop();
        }, {
          prompt: "Username: ",
          onStart: function() {
            Terminal.set_mask(false);
          }
        });
      }

    } else if (args[0] == "create") {
      var user, email, password;

      var calls = 0;    // stupid hack because onStart triggers twice for some reason
      var calls2 = 0;   // same thing...

      if (args[3]) {
        var data = History.data();
        data.pop();
        History.set(data);
        Terminal.pause();
        $.post(commandUrl, {command: "create", name: args[1], email: args[2], password: args[3], version: version}).then(function(response) {
          if (response.indexOf("Welcome, ") == 0) {
            Self = args[1];
          }
          Terminal.echo(response, {keepWords: true}).resume();
        });

      } else {
        Terminal.push(function(c) {
          password = c;
          Terminal.pop();
          History.enable();

          Terminal.pause();
          $.post(commandUrl, {command: "create", name: user, email: email, password: password, version: version}).then(function(response) {
            if (response.indexOf("Welcome, ") == 0) {
              Self = user;
            }
            Terminal.echo(response, {keepWords: true}).resume();
          });
        }, {
          prompt: "Password: ",
          onStart: function() {
            Terminal.set_mask(true);
            if (calls == 0) {
              calls += 1;
            } else {
              Terminal.echo("[[;lime;]Passwords are not required, but you will not be able to log back in.]", {keepWords: true});
            }
            History.disable();
          }
        });
      }

      if (args[2]) {
        email = args[2];
      } else {
        Terminal.push(function(c) {
          email = c;
          Terminal.pop();
        }, {
          prompt: "Email: ",
          onStart: function() {
            Terminal.set_mask(false);
            if (calls2 == 0) {
              calls2 += 1;
            } else {
              Terminal.echo("[[;lime;]Email addresses are not required, but you will not be able to reset your password.]\n[[;red;](Note: Password resets don't exist yet. Remind me to do that.)]", {keepWords: true});
            }
          }
        });

        if (args[1]) {
          user = args[1];
        } else {
          Terminal.push(function(c) {
            user = c;
            Terminal.pop();
          }, {
            prompt: "Username: ",
            onStart: function() {
              Terminal.set_mask(false);
            }
          });
        }
      }

    } else if (args[0] == "chpass") {
      if (args[1]) {
        var data = History.data();
        data.pop();
        History.set(data);
        return $.post(commandUrl, {command: "chpass", password: args[1], version: version});
      } else {
        Terminal.push(function(c) {
          Terminal.pop();
          History.enable();
          return $.post(commandUrl, {command: "chpass", password: c, version: version});
        }, {
          prompt: "Password: ",
          onStart: function() {
            Terminal.set_mask(true);
            Terminal.echo("[[;red;]WARNING][[;lime;]: You can set nothing as your password, but you won't be able to log in again.]", {keepWords: true});
            History.disable();
          }
        });
      }

    } else if (args[0] == "history") {
      if (args[1] == "-c" || args[1] == "clear") {
        History.clear();
      } else {
        var data = History.data();
        for (var i = 0; i < data.length; i++) {
          Terminal.echo(data[i], {keepWords: true});
        }
      }
      return false;

    } else {
      Terminal.pause();
      $.post(commandUrl, {command: command, version: version}).then(function(response) {
        Terminal.echo(response, {keepWords: true}).resume();
      });
    }
  }, {
    prompt: "> ",
    greetings: "[[;lime;]Welcome. Type 'help basics' and hit enter if you're new.]",
    // onBlur: function() {
    //   return false;
    // },
    exit: false,
    historySize: false,
    onInit: function(term) {
      Terminal = term;
      History = term.history();
      Terminal.echo("([[;red;]Note]: Sometimes when you [[;white;]login] or [[;white;]logout], you will immediately be logged out or logged back in, just repeat the action, and sorry for the inconvience. Also, [[;white;]create] always spits out a server error, but don't worry about that.)", {keepWords: true});
    }
  });
});

$(document).ready(function() {
  update(true); // first call gets 'true'
});
