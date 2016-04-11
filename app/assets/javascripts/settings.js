$(document).ready(function() {
  hash = window.location.hash.substring(1);
  $("#settings__a--" + hash).addClass("settings__form-a-selected");

  $("#settings__a--general").click(function() {
    $("#settings__a--general").addClass("settings__form-a-selected");
    $("#settings__a--users").removeClass("settings__form-a-selected");
  });

  $("#settings__a--users").click(function() {
    $("#settings__a--users").addClass("settings__form-a-selected");
    $("#settings__a--general").removeClass("settings__form-a-selected");
  });
});
