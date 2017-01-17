$(document).ready(function() {
  $("div[data-user-settings] button[type='submit']").click(function() {
    var userUrl = $(this).parent().parent().data("user-url");
    var user_session = {
      current_password: $("input[name='user_session[current_password]']").val(),
      password: $("input[name='user_session[password]']").val(),
      password_confirmation: $("input[name='user_session[password_confirmation]']").val(),
    }

    $.ajax({
      url: userUrl,
      method: "patch",
      dataType: "script",
      data: {
        utf8: true,
        name: name,
        user_session: user_session,
      },
    });
  });
});
