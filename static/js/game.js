$(function() {
  $('#terminal').terminal(function(command, term) {
    return $.post('https://ld39.guard13007.com/command', {command: command});
  }, {
    prompt: "  > ",
    greetings: "Welcome. Please type 'help' if you need help.",
    // onBlur: function() {
    //   return false;
    // },
    exit: false,
    historySize: false
  });
});
