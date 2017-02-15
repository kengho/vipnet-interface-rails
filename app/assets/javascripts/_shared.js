vipnetInterface = {
  nodes: {},
  params: {},
  localePageReloadTime: 1000,
  defaultSnackbarTime: 3000,

  snackbarContainer: function() {
    return $("#snackbar")[0];
  },

  showSnackbar: function(message, timeout = vipnetInterface.defaultSnackbarTime, callback = function(){}) {
    var snackbarContainer = vipnetInterface.snackbarContainer();
    var msgToShow = I18n["snackbar"][message] || message;

    var data = { message: msgToShow }
    if(timeout == -1) {
      data.timeout = 99999999;
      data.actionHandler = vipnetInterface.hideSnackbar;
      data.actionText = I18n["snackbar"]["close"];
    } else {
      data.timeout = timeout;
    }

    snackbarContainer.MaterialSnackbar.showSnackbar(data);
    callback.call();
  },

  hideSnackbar: function() {
    var snackbarContainer = vipnetInterface.snackbarContainer();
    snackbarContainer.MaterialSnackbar.cleanup_();
  },

  // http://stackoverflow.com/a/3169849
  clearSelection: function() {
    if(window.getSelection) {
      if(window.getSelection().empty) {
        window.getSelection().empty();
      } else if(window.getSelection().removeAllRanges) {
        window.getSelection().removeAllRanges();
      }
    } else if(document.selection) {
      document.selection.empty();
    }
  },

  bindEventRadio: function() {
    $("div[data-user-settings] input[type='radio']").change(function() {
      var userUrl = $(this).parent().data("user-url");
      var name = $(this).attr("name");
      var value = $(this).attr("value");

      $.ajax({
        url: userUrl,
        method: "patch",
        dataType: "script",
        data: {
          utf8: true,
          name: name,
          value: value,
        },
        success: function() {
          if(name == "nodes_per_page") {
            vipnetInterface.nodes.ajax.load(vipnetInterface.params);
          } else if(name == "locale") {
            setTimeout(
              function() { location.reload(); },
              vipnetInterface.localePageReloadTime
            );
          }
        },
      });
    });
  },

  // bindHome: function() {
  //   $("*[data-load='home']").click(function() {
  //     vipnetInterface.gotoPage(1);
  //   });
  // },

  gotoPage: function(page) {
    if(!page) {
      page = "1"
    }
    if(!vipnetInterface.params.page) {
      vipnetInterface.params.page = "1"
    }

    // if(vipnetInterface.params != { page: page })
    if(Object.keys(vipnetInterface.params).length > 1 || vipnetInterface.params.page != page) {
      $("#progress").vipnetInterface().tmpShow();
      vipnetInterface.params = { page: page };
      vipnetInterface.nodes.ajax.load();
    }
  },

  bindSelectRow: function() {
    $("*[data-selectable]").click(function(e) {
      var vid = $(this).data("vid");

      if(e.shiftKey) {
        vipnetInterface.nodes.export.shiftSelectRow(vid);
      } else {
        // http://stackoverflow.com/a/10390097/6376451
        // "e.button == 1" for middle button.
        // Prevents triggering by middle button or by selecting text.
        var selection = getSelection().toString();
        if(!selection && e.button != 1) {
          vipnetInterface.nodes.export.toggleSelectRow(vid);
        }
      }
    });
  },

  selectWhatWasSelected: function() {
    $("*[data-selectable]").each(function(_, row) {
      var vid = $(row).data("vid");
      var data = vipnetInterface.nodes.export.data[vid];
      if(data && data.selected) {
        vipnetInterface.nodes.export.selectRow(vid);
      }
    });
  },

  stopPropagation: function() {
    $("*[data-stop-propagation]").click(function(e) {
      e.stopPropagation();
    });
  },

  startUpdateCable: function() {
    App.cable.subscriptions.create({
      channel: "UpdateChannel",
    }, {
      received: function(data) {
        if(data.update) {
          vipnetInterface.nodes.ajax.load(vipnetInterface.params);
        }
      },
    });
  },

  clearSearchBar: function() {
    var $searchBar = $("#header__search").find("input[type=text]");
    if($searchBar.val()) { $searchBar.val(""); }
    $("#header__clear-search-bar").css("visibility", "hidden");
  },
};

$(document).ready(function() {
  // Radio buttons in header and profile.
  vipnetInterface.bindEventRadio();
  vipnetInterface.startUpdateCable();
});
