var Terminal;
var commandUrl = "https://ld39.guard13007.com/command";

$(function() {
  $('#terminal').terminal(function(command, term) {
    if (command.indexOf("exit ") == 0) {
      return false
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
    }
  });
});
