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
      // $(parentId).find("div[name='info']").remove();
    },

    renderUndoButton: function(args) {
      vipnetInterface.remoteStatus.remove({ parentId: args.parentId, div: "status--false" });
      vipnetInterface.remoteStatus.remove({ parentId: args.parentId, div: "status--true" });
      undoButtonHTML = $("#nodes__button-undo-template").html();
      $(args.parentId).append(undoButtonHTML);
      $shownUndoButton = vipnetInterface.remoteStatus.show({ parentId: args.parentId, div: "button--undo" });
      $shownUndoButton.click(function() {
        // unselect row
        vipnetInterface.selectRow("#" + $(args.parentId).parent().parent()[0].id);
        if(args.ids) {
          args.ids.forEach(function(id) {
            $(id).remove();
          });
        }
        vipnetInterface.remoteStatus.renderDefault(args.parentId);
      });
    },

    show: function(args) {
      $div = $(args.parentId + " div[name='" + args.div + "']")
      $div.css({
        "opacity": "1",
        "z-index": "400",
      });
      return $div;
    },

    hide: function(args) {
      $div = $(args.parentId + " div[name='" + args.div + "']")
      $div.css({
        "opacity": "0",
        "z-index": "0",
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
          });
        } else {
          $fullscreenTooltipTrigger.remove();
        }
      }
      if(args.undo) {
        setTimeout( vipnetInterface.remoteStatus.renderUndoButton,
                    vipnetInterface.remoteStatus.showStatusBeforeUndoTime,
                    { parentId: args.parentId, ids: args.ids });
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

      // http://stackoverflow.com/a/5462921
      $(document).delegate("a[data-replace-link-by-spinner]", "click", function() {
        vipnetInterface.remoteStatus.initAjax(this);
      });
    },

    renderInfo: function(args) {
      $(args.parentId).append(args.html);
      $infoBlock = vipnetInterface.remoteStatus.show({ parentId: args.parentId, div: "info" });
      // $infoBlock.find("div[name='close']").click(function() {
      //   vipnetInterface.remoteStatus.renderDefault(args.parentId);
      // });
    },

    initAjax: function(parent) {
      id = $(parent).parent().attr("id");
      vipnetInterface.remoteStatus.renderSpinner("#" + id);
      vipnetInterface.remoteStatus.ajaxTimeoutHandlers["#" + id] = setTimeout(function() {
        spinner_visibility = $("#" + id).parent().find("div[name='spinner']").css("visibility");
        if(spinner_visibility == "visible") {
          // http://stackoverflow.com/a/10610347
          vipnetInterface.remoteStatus.renderStatus({ parentId: "#" + id, status: "false", tooltipText: I18n["ajax_error"] });
        }
      }, vipnetInterface.remoteStatus.ajaxTimeout, id)
    },
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

  selectedRows: [],
  selectRow: function(rowId) {
    $row = $(rowId);
    $row.toggleClass("nodes__row--selected");
    rowIdPosition = vipnetInterface.selectedRows.indexOf(rowId);
    if(rowIdPosition == -1) {
      vipnetInterface.selectedRows.push(rowId);
    } else {
      vipnetInterface.selectedRows.splice(rowIdPosition, 1);
    }
    // fill textarea
    var $copyTextarea = $("#nodes__export-selected textarea");
    $copyTextarea.val("");
    vipnetInterface.selectedRows.sort(function(a,b) {
      return vipnetInterface.nodesData[a].vipnetId.localeCompare(vipnetInterface.nodesData[b].vipnetId)
    });
    vipnetInterface.selectedRows.forEach(function(selectedRow) {
      var vipnetId = vipnetInterface.nodesData[selectedRow].vipnetId;
      var name = vipnetInterface.nodesData[selectedRow].name;
      $copyTextarea.val($copyTextarea.val() + vipnetId + " " + name + "\n");
    });
    // update badge and button
    selectedRowsLength = vipnetInterface.selectedRows.length;
    if(selectedRowsLength > 0) {
      $("#nodes__export-selected").attr("data-badge", selectedRowsLength);
      $("#nodes__export-selected label").removeAttr("disabled");
    } else {
      $("#nodes__export-selected").removeAttr("data-badge");
      $("#nodes__export-selected label").attr("disabled", "disabled");
    }
  },
};

$(document).ready(function() {
  $("a[data-replace-link-by-spinner]").click(function(e) {
    vipnetInterface.remoteStatus.initAjax(this);
    // unselect row
    vipnetInterface.selectRow("#" + $(this).parent().parent().parent()[0].id);
  });

  $("span[data-fullscreen-tooltip-key]").click(function() {
    fullscreenTooltipKey = $(this).data("fullscreen-tooltip-key");
    vipnetInterface.showFullscreenTooltip(fullscreenTooltipKey);
  });

  $("#nodes__search-button--clear").click(function() {
    $theadRow = $(this).parent().parent().parent();
    $inputs = $theadRow.find("input");
    $inputs.each(function(_, input) {
      $(input)
        .val("")
        .parent().removeClass("is-dirty")
    });
  });

  $(".nodes__row").click(function(e) {
    // http://stackoverflow.com/a/10390097/6376451
    // e.button == 1 for middle button
    var selection = getSelection().toString();
    if(!selection && e.button != 1){
      vipnetInterface.selectRow("#" + this.id);
    }
  });

  // if I don't show textarea, I don't need this
  // $("#nodes__export-selected").mouseenter(function() {
  //   if(!$("#nodes__export-selected label").attr("disabled")) {
  //     $("#nodes__export-selected textarea").css("visibility", "visible");
  //   }
  // });
  // $("#nodes__export-selected").mouseleave(function() {
  //   if(!$("#nodes__export-selected label").attr("disabled")) {
  //     $("#nodes__export-selected textarea").css("visibility", "hidden");
  //   }
  // });
  $("#nodes__export-selected").click(function() {
    if(!$("#nodes__export-selected label").attr("disabled")) {
      // http://stackoverflow.com/a/30810322
      var $copyTextarea = $("#nodes__export-selected textarea");
      $copyTextarea.select();
      document.execCommand("copy");
      // if I don't show textarea, I don't need this
      // $("#nodes__export-selected textarea").css("visibility", "hidden");
    }
  });
});
