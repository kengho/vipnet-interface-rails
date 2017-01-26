$(document).ready(function() {
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

  $("div[data-clear-search-bar]").click(function() {
    vipnetInterface.clearSearchBar();
    vipnetInterface.gotoPage(vipnetInterface.params.page);
  });
});
