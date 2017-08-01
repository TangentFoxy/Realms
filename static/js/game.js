var commandUrl = "https://realms.guard13007.com/command";
var version = 0;    // the first update() call gets the current version
var timeOut = 30;   // the first update() call overwrites this value from the server
var updateTimer;    // used by/for setTimeout on update loop

var Terminal;
var History;

var Self;         // defined by update() when logged in
var Characters = {};
var Events = {};

function update() {
  $.post(commandUrl, {command: "update", version: version}, function(data, status) {
    if (status == "success") {
      console.log(data);

      if (typeof(data) == "string") {
        Terminal.echo(data + "\n[[b;pink;]You have been disconnected from the update loop to prevent this error message from repeating. Please try reloading the page later.]");
        return false;
      }

      if (version == 0) {
        version = data.version;
        updateTimer = setTimeout(update, 1);
        return true;
      }

      if (data.echo) {
        Terminal.echo(data.echo, {keepWords: true}); // TODO document the echo feature for personal use in like a server-wide announcement or whatever. Or don't. I want a global event to be possible anyhow.
      }

      var justEntered = false;
      if (data.you) {
        if (!Self) {
          justEntered = true;
        }
        Self = data.you;
      }

      for (var character in data.characters) {
        if (!Characters[character]) {
          if (character != Self.name) {
            Characters[character] = character;

            if (justEntered) {
              if (data.characters[character].alive) {
                Terminal.echo("[[;white;]" + character + "] is here.", {keepWords: true});
              } else {
                Terminal.echo("[[;white;]" + character + "]'s corpse is here.", {keepWords: true});
              }
            } else {
              Terminal.echo("[[;white;]" + character + "] enters.", {keepWords: true});
            }
          }
        }
      }

      for (var character in Characters) {
        if (!data.characters[character]) {
          if (character == Self.name) {
            Terminal.echo("[[;red;]Somehow, you have left. Please refresh the page.]", {keepWords: true});
          } else {
            delete Characters[character];
            Terminal.echo("[[;white;]" + character + "] has left.", {keepWords: true});
          }
        }
      }

      for (var i = 0; i < data.events.length; i++) {
        var e = data.events[i];
        if (!Events[e.id]) {
          Events[e.id] = e;
        }
      }

      var now = Math.floor(Date.now() / 1000);
      for (var ev in Events) {
        var e = Events[ev];
        if (!e.done) {
          if (event.targeted && event.type == "punch") {
            Terminal.echo("[[;white;]" + event.source + "] punched you!", {keepWords: true});
            if (Self.health <= 0) {
              Terminal.echo("[[;red;]You are dead.]", {keepWords: true});
            }
          } else if (event.type == "report") {
            Terminal.echo("[[;orange;]" + event.id + "]: " + event.msg, {keepWords: true}); // NOTE might not be needed? (as in, the adding of the ID)
          } else {
            Terminal.echo(event.msg, {keepWords: true});
          }
          e.done = true;
        }

        if (event.time < (now - timeOut * 2)) {
          delete Events[ev];
        }
      }
    } else {
      Terminal.echo("[[;red;]Connection/Server error]: " + status + "\n[[b;pink;]You have been disconnected from the update loop to prevent this error message from repeating. Please try reloading the page later.]", {keepWords: true});
    }
  });

  // flat out doesn't work
  // if (Self) { // currently doesn't handle logouts does it?
  //   updateTimer = setTimeout(update, 1000);
  // }
  updateTimer = setTimeout(update, 1000);
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
      var name, password;

      if (args[2]) {
        var data = History.data();
        data.pop();
        History.set(data);
        Terminal.clear();
        $.post(commandUrl, {command: "login " + args[1] + " " + args[2], version: version}).then(function(response) {
          Terminal.echo(response, {keepWords: true});
        });
      } else {
        Terminal.push(function(c) {
          password = c;
          Terminal.pop();
          History.enable();
          $.post(commandUrl, {command: "login " + name + " " + password, version: version}).then(function(response) {
            Terminal.echo(response, {keepWords: true});
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

    } else if (args[0] == "create") { // TODO document to use 'none' for no email address
      var name, email, password;

      var passwordAlert = false;    // stupid hack because onStart triggers twice for some reason
      var emailAlert = false;   // same thing...

      if (args[3]) {
        var data = History.data();
        data.pop();
        History.set(data);
        Terminal.clear();
        $.post(commandUrl, {command: "create " + args[1] + " " + args[2] + " " + args[3], version: version}).then(function(response) {
          Terminal.echo(response, {keepWords: true});
        });

      } else {
        Terminal.push(function(c) {
          password = c;
          Terminal.pop();
          History.enable();
          $.post(commandUrl, {command: "create " + name + " " + email + " " + password, version: version}).then(function(response) {
            Terminal.echo(response, {keepWords: true});
          });
        }, {
          prompt: "Password: ",
          onStart: function() {
            Terminal.set_mask(true);
            if (passwordAlert == false) {
              passwordAlert = true;
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
          if (c.length > 0) {
            email = c;
          } else {
            email = "none"; // dirty hack because of issues with json_params
          }
          Terminal.pop();
        }, {
          prompt: "Email: ",
          onStart: function() {
            Terminal.set_mask(false);
            if (emailAlert == false) {
              emailAlert = true;
            } else {
              Terminal.echo("[[;lime;]Email addresses are not required, but you will not be able to reset your password.]\n[[;red;](Note: Password resets don't exist yet. Remind me to do that.)]", {keepWords: true});
            }
          }
        });

        if (args[1]) {
          user = args[1];
        } else {
          Terminal.push(function(c) {
            name = c;
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
        Terminal.clear();
        $.post(commandUrl, {command: "chpass " + args[1], version: version}).then(function(response) {
          Terminal.echo(response, {keepWords: true});
        });
      } else {
        Terminal.push(function(c) {
          Terminal.pop();
          History.enable();
          $.post(commandUrl, {command: "chpass " + c, version: version}).then(function(response) {
            Terminal.echo(response, {keepWords: true});
          });
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
      $.post(commandUrl, {command: command, version: version}).then(function(response) {
        Terminal.echo(response, {keepWords: true});
      });
    }
  }, {
    prompt: "> ",
    greetings: "[[;lime;]Welcome. Type 'help basics' and hit enter if you're new.]",
    exit: false,
    historySize: false,
    onInit: function(term) {
      Terminal = term;
      History = term.history();
      Terminal.echo("[[;lime;]This is a post-Ludum Dare version. DO NOT BASE YOUR RATING ON THIS VERSION!!]");
    }
  });
});

$(document).ready(function() {
  update();
});
