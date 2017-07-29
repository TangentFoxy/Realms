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
      Terminal.set_mask(true);
      Terminal.push(function(c) {
        password = c;
        Terminal.pop();
        Terminal.set_mask(false);
        Terminal.echo("Name: " + user " Password: " + password);
        return $.post(commandUrl, {command: "login", name: user, password: password});
        History.enable();
      }, {
        prompt: "Password: "
      });

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

      // now log in
      // return $.post(commandUrl, {command: "login", name: user, password: password});
      // History.disable(); Terminal.set_mask(true); Terminal.push(function(c) { Terminal.clear(); Terminal.echo('do something'); Terminal.pop(); History.enable(); }, {prompt: "COMMAND PROMPT"});

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
