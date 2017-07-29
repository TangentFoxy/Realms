var commandUrl = "https://ld39.guard13007.com/command";

var Terminal;
var History;

$(function() {
  $('#terminal').terminal(function(command, term) {
    if (command == "") { return false; }

    var args = command.split(" ");

    if (args[0] == "exit") {
      return $.post(commandUrl, {command: "logout"});

    } else if (args[0] == "login") {
      var user, password;

      if (args[2]) {
        var data = History.data();
        data.pop();
        History.set(data);
        return $.post(commandUrl, {command: "login", name: args[1], password: args[2]});
      } else {
        Terminal.push(function(c) {
          password = c;
          Terminal.pop();
          History.enable();

          return $.post(commandUrl, {command: "login", name: user, password: password});
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

      Terminal.push(function(c) {
        password = c;
        Terminal.pop();
        History.enable();

        return $.post(commandUrl, {command: "create", name: user, email: email, password: password});
        // Terminal.pause();
        // $.post(commandUrl, {command: "create", name: user, email: email, password: password}).then(function(response) {
        //   Terminal.echo(response).resume();
        // });
      }, {
        prompt: "Password: ",
        onStart: function() {
          Terminal.set_mask(true);
          Terminal.echo("[[;lime;]Passwords are not required, however, if you log out or the session cookie for ld39.guard13007.com is removed, you will not be able to log in again.]", {keepWords: true});
          History.disable();
        }
      });

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
            Terminal.echo("[[;lime;]Email addresses are not required, however, you will not be able to reset your password if you forget it.]\n[[;red;](Note: Password resets don't exist yet. Remind me to do that.)]", {keepWords: true});
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
      // return $.post(commandUrl, {command: command});
      Terminal.pause();
      $.post(commandUrl, {command: command}).then(function(response) {
        Terminal.echo(response).resume();
      });
    }
  }, {
    prompt: "> ",
    greetings: "Welcome. Please type 'help' if you need help.",
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
