var vipnetInterface = {
  remoteStatus: {
    showStatusTime: 5000,
    showStatusBeforeUndoTime: 1000,
    ajaxTimeout: 15000,
    ajaxTimeoutHandlers: {},

    renderDefault: function(parentId) {
      vipnetInterface.remoteStatus.show  ({ parentId: parentId, div: "button" });
      vipnetInterface.remoteStatus.remove({ parentId: parentId, div: "status--false" });
      vipnetInterface.remoteStatus.remove({ parentId: parentId, div: "status--true" });
      vipnetInterface.remoteStatus.remove({ parentId: parentId, div: "button--undo" });
    },

    renderUndoButton: function(args) {
      vipnetInterface.remoteStatus.remove({ parentId: args.parentId, div: "status--false" });
      vipnetInterface.remoteStatus.remove({ parentId: args.parentId, div: "status--true" });
      undoButtonHTML = $("#nodes__button-undo-template").html();
      $(args.parentId).append(undoButtonHTML);
      $shownUndoButton = vipnetInterface.remoteStatus.show({ parentId: args.parentId, div: "button--undo" });
      $shownUndoButton.click(function() {
        args.row_ids.forEach(function(row_id) {
          $(row_id).remove();
          vipnetInterface.remoteStatus.renderDefault(args.parentId);
        });
      })
    },

    show: function(args) {
      $div = $(args.parentId + " div[name='" + args.div + "']")
      $div.css({
        "opacity" : "1",
        "visibility" : "visible",
        "z-index" : "400",
      });
      return $div;
    },

    hide: function(args) {
      $div = $(args.parentId + " div[name='" + args.div + "']")
      $div.css({
        "opacity" : "0",
        "visibility" : "hidden",
        "z-index" : "200",
      });
      return $div;
    },

    remove: function(args) {
      $div = $(args.parentId + " div[name='" + args.div + "']")
      $div.remove();
      return $div;
    },

    renderSpinner: function(parentId) {
      spinnerHTML = $("#nodes__spinner-template").html();
      $hiddenButton = vipnetInterface.remoteStatus.hide({ parentId: parentId, div: "button" });
      $hiddenButton.parent().append(spinnerHTML);
      $shownSpinner = vipnetInterface.remoteStatus.show({ parentId: parentId, div: "spinner" });
      return $shownSpinner;
    },

    renderStatus: function(args) {
      // http://stackoverflow.com/a/1472717
      window.clearTimeout(vipnetInterface.remoteStatus.ajaxTimeoutHandlers[args.parentId]);
      statusHTML = $("#nodes__status-" + args.status + "-template").html();
      $(args.parentId).append(statusHTML);
      $shownStatus = vipnetInterface.remoteStatus.show({ parentId: args.parentId, div: "status--" + args.status });
      $shownStatus.find("div[name='tooltip_text']").html(args.tooltipText);
      vipnetInterface.remoteStatus.remove({ parentId: args.parentId, div: "spinner" });
      $fullscreenTooltipTrigger = $shownStatus.find("span[name='fullscreen_tooltip_trigger']");
      if($fullscreenTooltipTrigger.length) {
        if(args.fullscreenTooltipKey) {
          $fullscreenTooltipTrigger.click(function() {
            vipnetInterface.showFullscreenTooltip(args.fullscreenTooltipKey);
          })
        } else {
          $fullscreenTooltipTrigger.remove();
        }
      }
      if(args.undo) {
        setTimeout( vipnetInterface.remoteStatus.renderUndoButton,
                    vipnetInterface.remoteStatus.showStatusBeforeUndoTime,
                    { parentId: args.parentId, row_ids: args.row_ids });
      } else {
        setTimeout( vipnetInterface.remoteStatus.renderDefault,
                    vipnetInterface.remoteStatus.showStatusTime,
                    args.parentId);
      }
    },

    showHistory: function(args) {
      args.rows.forEach(function(row) {
        $(args.parentId)[args.place](row);
      });
    }
  },

  showFullscreenTooltip: function(fullscreenTooltipKey) {
    $("#fullscreen-tooltip__" + fullscreenTooltipKey)
      .css("z-index", "1000")
      .css("display", "table-cell")

      // hide fullscreen tooltip by clicking outside
      .click(function() {
        vipnetInterface.closeFullscreenTooltip(fullscreenTooltipKey);
      })

      // don't hide fullscreen tooltip by clicking inside
      .find("div[name='inner']")
        .click(function(e) {
          e.stopPropagation();
        })

    // hide fullscreen tooltip by pressing "ESC"
    $(document).keyup(fullscreenTooltipKey, function(e) {
      if (e.which == 27) {
        vipnetInterface.closeFullscreenTooltip(e.data);
        $(document).unbind("keyup");
      }
    });
  },

  closeFullscreenTooltip: function(fullscreenTooltipKey) {
    $("#fullscreen-tooltip__" + fullscreenTooltipKey)
      .css("z-index", "0")
      .css("display", "none")
  },
};

$(document).ready(function() {
  $("a[data-replace-link-by-spinner]").click(function() {
    id = $(this).parent().attr("id");
    vipnetInterface.remoteStatus.renderSpinner("#" + id);
    vipnetInterface.remoteStatus.ajaxTimeoutHandlers["#" + id] = setTimeout(function() {
      spinner_visibility = $("#" + id).parent().find("div[name='spinner']").css("visibility");
      if(spinner_visibility == "visible") {
        // http://stackoverflow.com/a/10610347
        vipnetInterface.remoteStatus.renderStatus({ parentId: "#" + id, status: "false", tooltipText: I18n["ajax_error"] });
      }
    }, vipnetInterface.remoteStatus.ajaxTimeout, id)
  });

  $("span[data-fullscreen-tooltip-key]").click(function() {
    fullscreenTooltipKey = $(this).data("fullscreen-tooltip-key");
    vipnetInterface.showFullscreenTooltip(fullscreenTooltipKey);
  });
});
