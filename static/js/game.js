var commandUrl = "https://ld39.guard13007.com/command";

var Terminal;
var History;

$(function() {
  $('#terminal').terminal(function(command, term) {
    var args = command.split(" ");

    if (args[0] == "exit") {
      // TODO have this log you out
      return false

    } else if (args[0] == "login") {
      var user, password

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

      if (args[1]) {
        user = args[1]
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

    } else {
      // return $.post(commandUrl, {command: command});
      term.pause();
      $.post(commandUrl, {command: command}).then(function(response) {
        term.echo(response).resume();
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
