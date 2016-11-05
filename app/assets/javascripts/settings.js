$(document).ready(function() {
  var anchor = window.location.hash.substring(1);
  displaySettings(anchor);

  $("a[data-anchor]").click(function() {
    var anchor = $(this).data("anchor");
    displaySettings(anchor);
    vipnetInterface.hideSnackbar();
  });

  function displaySettings(tab) {
    location.href = "#" + tab;
    $("a[data-anchor]").each(function(_, a) {
      var iteratingTab = $(a).data("anchor");
      var settingsDivQuery = "#" + iteratingTab + "-settings";
      var linkIdQuery = "a[data-anchor='" + iteratingTab + "']";
      if(iteratingTab == tab) {
        $(settingsDivQuery).css("display", "block");
        $(linkIdQuery).addClass("settings__tab--selected");
      } else {
        $(settingsDivQuery).css("display", "none");
        $(linkIdQuery).removeClass("settings__tab--selected");
      }
    });
  };
});

// http://stackoverflow.com/a/36088776/6376451
// http://stackoverflow.com/a/5182050/6376451
$(window).load(function() {
  var flash = $("div[data-flash]");
  if(flash) {
    var message = $(flash).data("message");
    if(message) {
      var timeout = $(flash).data("timeout");
      vipnetInterface.showSnackbar(message, timeout);
    }
  }
});
