// http://stackoverflow.com/a/11620267/6376451
$.fn.vipnetInterface = function() {
  this.tmpHide = function() {
    var $e = $(this[0]);
    var zIndex = $e.css("z-index") || "auto";
    $e
      .css({ "opacity": "0", "z-index": "0" })
      .attr({ "data-z-index": zIndex });
    return $e;
  };

  this.tmpShow = function() {
    var $e = $(this[0]);
    var zIndex = $e.attr("data-z-index") || "auto";
    $e
      .css({ "opacity": "1", "z-index": zIndex })
      .removeAttr("data-z-index");
    return $e;
  };

  return this;
};

vipnetInterface.nodes.ajax = {
  showStatusTime: 5000,
  showRemoteInfoTime: 120000,
  animationTime: 200,
  timeout: 15000,
  history: false,

  urls: {
    load: "/nodes/load",
    info: "/nodes/info",
    history: "/nodes/history",
    availability: "/nodes/availability",
  },

  bindProgress: function() {
    $(".pagination a").click(function() {
      $("#progress").vipnetInterface().tmpShow();
    });

    $("div[data-user-settings] input[type='radio'][name='nodes_per_page']").change(function() {
      $("#progress").vipnetInterface().tmpShow();
    })

    // http://stackoverflow.com/a/11365868/6376451
    $("#header__search input").keypress(function(e) {
        var event = e || window.event;
        var charCode = event.which || event.keyCode;
        // <Enter>
        if(charCode == "13") {
          $("#progress").vipnetInterface().tmpShow();
        }
    })

    $("#header__search-button").click(function() {
      $("#progress").vipnetInterface().tmpShow();
    });
  },

  bindRemoteButtons: function() {
    $("*[name='button'][data-action-name]").click(function() {
      var action = $(this).data("action-name");
      var vid = $(this).closest(".tr").data("vid");
      var prop = $(this).data("action-prop");

      vipnetInterface.nodes.ajax.doAction({
        action: action,
        data: {
          vid: vid,
          prop: prop,
        },
      });
    });
  },

  load: function(data, history = false) {
    vipnetInterface.nodes.ajax.history = history;
    $.ajax({
      url: vipnetInterface.nodes.ajax.urls["load"],
      method: "get",
      dataType: "script",
      data: data,
      timeout: vipnetInterface.nodes.ajax.timeout,
      // http://stackoverflow.com/a/14563181/6376451
      error: function() {
        vipnetInterface.showSnackbar(I18n["ajax_error"]);
      },
    }).complete(function() {
      vipnetInterface.nodes.ajax.history = false;
    });
  },

  doAction: function(params) {
    vipnetInterface.nodes.ajax.renderSpinner(params);
    $.ajax({
      url: vipnetInterface.nodes.ajax.urls[params.action],
      method: "get",
      dataType: "script",
      data: params.data,
      timeout: vipnetInterface.nodes.ajax.timeout,
      error: function() {
        vipnetInterface.showSnackbar(I18n["ajax_error"]);
        vipnetInterface.nodes.ajax.renderDefault(params);
      },
    });
  },

  button: function($row, action, prop = null) {
    if(prop) {
      return $row.find("*[data-action-name='" + action + "'][data-action-prop='" + prop + "']");
    } else {
      return $row.find("*[data-action-name='" + action + "']");
    }
  },

  spinner: function($button) {
    return $button.parent().find("*[name='spinner']");
  },

  renderLoad: function(args) {
    $("#progress").vipnetInterface().tmpHide();

    if($("#header__subtitle").html() != args.subtitle) {
      $("#header__subtitle")
        .fadeOut(vipnetInterface.nodes.ajax.animationTime, function() {
          $("#header__subtitle")
            .html(args.subtitle)
            .fadeIn(vipnetInterface.nodes.ajax.animationTime);
      });
    }

    $(".nodes")
      .fadeOut(vipnetInterface.nodes.ajax.animationTime, function() {
        $("#nodes-container")
          .html(args.html)
          .fadeIn(vipnetInterface.nodes.ajax.animationTime, function() {
            // radio in nodes_per_page
            vipnetInterface.bindEventRadio();
            vipnetInterface.bindSelectRow();
            vipnetInterface.stopPropagation();
            vipnetInterface.selectWhatWasSelected();
            vipnetInterface.nodes.ajax.bindProgress();
            vipnetInterface.nodes.ajax.bindRemoteButtons();
          });
      });

    vipnetInterface.params = args.params;
    if(!vipnetInterface.nodes.ajax.history) {
      window.history.pushState(args.params, null, "nodes?" + args.paramsQuery);
    }
  },

  renderSpinner: function(args) {
    var $row = vipnetInterface.nodes.row(args.data.vid);
    var $button = vipnetInterface.nodes.ajax.button($row, args.action, args.data.prop);
    var spinnerHTML = $("#spinner-template").html();

    $button
      .vipnetInterface().tmpHide()
      .parent()
      .append(spinnerHTML);
  },

  renderStatus: function(args) {
    var $row = vipnetInterface.nodes.row(args.data.vid);
    var $button = vipnetInterface.nodes.ajax.button($row, args.action, args.data.prop);
    var $spinner = vipnetInterface.nodes.ajax.spinner($button);
    var statusHTML = $("#status-template--" + args.data.status).html();

    $spinner
      .remove();

    $button
      .parent()
      .append(statusHTML)
      .find("*[name='tooltip-text']")
      .html(args.data.tooltipText);

    setTimeout(
      vipnetInterface.nodes.ajax.renderDefault,
      vipnetInterface.nodes.ajax.showStatusTime,
      args
    );
  },

  renderDefault: function(args) {
    var $row = vipnetInterface.nodes.row(args.data.vid);
    var $button = vipnetInterface.nodes.ajax.button($row, args.action, args.data.prop);

    $button
      .vipnetInterface().tmpShow()
      .parent()
      .find("*[name='status--true'], *[name='status--false'], *[name='spinner']")
      .remove();
  },

  renderInfoBlock: function(args) {
    var $row = vipnetInterface.nodes.row(args.vid);
    var $button = vipnetInterface.nodes.ajax.button($row, "info");
    var $td = $button.parent();

    var $infoBlock = $td.find("*[name='info-block']");
    if($infoBlock.length == 0) {
      $td.append(args.html);

      var $infoBlock = $td.find("*[name='info-block']");

      $infoBlock
        .draggable({
          cancel: "*[data-undraggable]",
          containment: "#nodes-container",
        })
        .click(function(e) {
          e.stopPropagation();
        });

      vipnetInterface.nodes.ajax.bindCloseButton($infoBlock);

      setTimeout(
        vipnetInterface.nodes.ajax.closeBlock,
        vipnetInterface.nodes.ajax.showRemoteInfoTime,
        $infoBlock
      );
    }
  },

  renderHistory: function(args) {
    var $row = vipnetInterface.nodes.row(args.vid);

    // @TODO store selector somehow
    var $history = $row.nextAll("*[name='history'][data-prop='" + args.prop + "']");
    if($history.length == 0) {
      $row.after(args.html);
      var $history = $row.nextAll("*[name='history'][data-prop='" + args.prop + "']");
      vipnetInterface.nodes.ajax.bindCloseButton($history);

      setTimeout(
        vipnetInterface.nodes.ajax.closeBlock,
        vipnetInterface.nodes.ajax.showRemoteInfoTime,
        $history
      );
    }
  },

  bindCloseButton: function($DOM) {
    $DOM
      .find("*[data-close]")
      .click(function() {
        vipnetInterface.nodes.ajax.closeBlock($(this));
      })
  },

  closeBlock: function($smthCloseToBlock) {
    $smthCloseToBlock
      .closest("*[data-closable]")
      .fadeOut(vipnetInterface.nodes.ajax.animationTime, function() {
        this.remove();
      });
  },
}

$(document).ready(function() {
  // https://developer.mozilla.org/en-US/docs/Web/Events/popstate
  window.onpopstate = function(event) {
    if(event.state && document.location.pathname.match(RegExp("nodes"))) {
      vipnetInterface.nodes.ajax.load(event.state, true);
      $("#progress").vipnetInterface().tmpShow();
    }
  };
});
