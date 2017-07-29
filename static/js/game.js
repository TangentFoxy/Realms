var commandUrl = "https://ld39.guard13007.com/command";
var version = 2; // internal version number indicating only changes on client-side requiring a user to refresh their page

var Terminal;
var History;

function update() {
  $.post(commandUrl + "/update", {version: version}, function(data, status) {
    if (status == "success") {
      if (typeof(data) == "string") {
        Terminal.echo("[[b;pink;]SERVER ERROR]: [[;red;]" + data.slice(1, data.indexOf("\n") - 1) + "]");
      } else if (data.echo) {
        Terminal.echo(data.echo);
      }
    } else {
      Terminal.echo("[[b;pink;]Connection/Server error]: " + status);
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
        Terminal.echo(response);
      });
      window.close(); // may or may not be permitted by the browser

    } else if (args[0] == "login") {
      var user, password;

      if (args[2]) {
        var data = History.data();
        data.pop();
        History.set(data);
        return $.post(commandUrl, {command: "login", name: args[1], password: args[2], version: version});
      } else {
        Terminal.push(function(c) {
          password = c;
          Terminal.pop();
          History.enable();

          return $.post(commandUrl, {command: "login", name: user, password: password, version: version});
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
        return $.post(commandUrl, {command: "create", name: args[1], email: args[2], password: args[3], version: version});
      } else {
        Terminal.push(function(c) {
          password = c;
          Terminal.pop();
          History.enable();

          return $.post(commandUrl, {command: "create", name: user, email: email, password: password, version: version});
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

    } else if (args[0] == "history") {
      if (args[1] == "-c" || args[1] == "clear") {
        History.clear();
      } else {
        var data = History.data();
        for (var i = 0; i < data.length; i++) {
          Terminal.echo(data[i]);
        }
      }
      return false;

    } else {
      return $.post(commandUrl, {command: command, version: version});
    }
  }, {
    prompt: "> ",
    greetings: "[[;lime;]Welcome. Please type 'help' if you need help.]",
    // onBlur: function() {
    //   return false;
    // },
    exit: false,
    historySize: false,
    onInit: function(term) {
      Terminal = term;
      History = term.history();
    }
  });
});

$(document).ready(function() {
  setTimeout(update, 1000);
});
