$(document).ready(function() {
  $("*[data-load='home']").click(function(e) {
    // "e.button == 1" for middle button.
    if(e.button == 1) {
      window.open("nodes", "_blank")
    } else {
      vipnetInterface.gotoPage(1);
    }
  });

  $("#actions__export-selected").click(function() {
    if(!$("#actions__export-selected label").attr("disabled")) {
      // http://stackoverflow.com/a/30810322
      $("#actions__export-selected textarea")
      .val(vipnetInterface.nodes.export.exportData())
      .select();
      document.execCommand("copy");
      vipnetInterface.showSnackbar("copied");
    }
  });

  $("#actions__unselect-all").click(function() {
    vipnetInterface.nodes.export.unselectAllRows();
  });

  $("#header__select-all").click(function() {
    vipnetInterface.nodes.export.selectAllRows();
  });

  $("div[data-clear-search-bar]").click(function() {
    vipnetInterface.clearSearchBar();
    vipnetInterface.gotoPage(vipnetInterface.params.page);
  });

  $("div[data-toggle-dark-theme]").click(function() {
    var userUrl = $(this).data("user-url");

    $.ajax({
      url: userUrl,
      method: "patch",
      dataType: "script",
      data: {
        utf8: true,
        name: "theme",
        value: $("html").hasClass("dark") ? "" : "dark",
      },
    });

    $("html").toggleClass("dark");
  });
});
