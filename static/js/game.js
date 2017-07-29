$(function() {
  $('#terminal').terminal(function(command, term) {
    return " " + $.post('https://ld39.guard13007.com/command', {command: command});
  }, {
    //prompt: ">",
    greetings: "Test?",
    onBlur: function() {
      return false;
    }
  });
});
