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
      History.disable();
      if (args[1]) {
        user = args[1]
      } else {
        Terminal.push(function(c) {
          user = c;
          Terminal.pop();
        }, {
          prompt: "Username: "
        });
      }

      Terminal.set_mask(true);
      Terminal.push(function(c) {
        password = c;
        Terminal.pop();
        Terminal.set_mask(false);
        History.enable();
      }, {
        prompt: "Password: "
      });

      // now log in
      return $.post(commandUrl, {command: "login", name: user, password: password});

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
