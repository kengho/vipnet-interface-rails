$(document).ready(function() {
  $("#reset-password-button").click(function() {
    var email = $(this)
      .closest("form")
      .find("input[name='user_session[email]']")
      .val();

    $.ajax({
      url: "/reset_password?email=" + email,
      method: "get",
      dataType: "script",
    });
  });
});
