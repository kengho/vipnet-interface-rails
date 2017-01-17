vipnetInterface.nodes = {
  ajax: {},
  export: {},

  row: function(vid) {
    return $("*[data-vid='" + vid + "']");
  },
};

$(document).ready(function() {
  $("div[data-clear-search-bar]").click(function() {
    var $searchBar = $(this).parent().find("input[type=text]");
    $searchBar.val("");
  });
});
