$(function() {
  $('#terminal').terminal(function(command, term) {
    return $.post('https://ld39.guard13007.com/', {command: command});
  }, {
    greetings: "Test?",
    onBlur: function() {
      return false;
    }
  });
});
