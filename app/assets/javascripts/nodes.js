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
      $(args.parentId).append(args.html);
      $shownUndoButton = vipnetInterface.remoteStatus.show({ parentId: args.parentId, div: "button--undo" });
      $shownUndoButton.click(function() {
        // unselect current row
        vipnetInterface.selectRow("#" + $(args.parentId).parent().parent()[0].id);
        // delete and unselect rows
        if(args.ids) {
          args.ids.forEach(function(id) {
            // remove row visually, from selectedRows, and from nodesData
            $(id).remove();
            rowIdPosition = vipnetInterface.selectedRows.indexOf(id);
            if(!(rowIdPosition == -1)) {
              vipnetInterface.selectRow(id);
            }
            delete vipnetInterface.nodesData[id];
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
      vipnetInterface.showSnackbar(args.tooltipText);
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
                    { parentId: args.parentId, ids: args.ids, html: args.html });
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
      for(var id in args.data) {
        vipnetInterface.nodesData[id] = args.data[id];
        $(id)
          .addClass("nodes__row--ajax")
          .click(function(e) {
            if(vipnetInterface.singleClick(e)) {
              vipnetInterface.selectRow("#" + this.id);
            }
          });
        setTimeout(function() {
          for(var id in args.data) {
            $(id).removeClass("nodes__row--ajax");
          }
        }, 300);
      }

      // http://stackoverflow.com/a/5462921
      $(document).delegate("a[data-replace-link-by-spinner]", "click", function() {
        vipnetInterface.remoteStatus.initAjax(this);
      });
    },

    renderInfo: function(args) {
      $(args.parentId).append(args.html);
      $infoBlock = vipnetInterface.remoteStatus.show({ parentId: args.parentId, div: "info" });
    },

    initAjax: function(parent) {
      id = $(parent).parent().attr("id");
      spinner_visibility = vipnetInterface.remoteStatus.spinnerVisibility(id)
      if(!spinner_visibility) {
        vipnetInterface.remoteStatus.renderSpinner("#" + id);
        vipnetInterface.remoteStatus.ajaxTimeoutHandlers["#" + id] = setTimeout(function() {
          spinner_visibility = vipnetInterface.remoteStatus.spinnerVisibility(id)
          if(spinner_visibility == "visible") {
            // http://stackoverflow.com/a/10610347
            vipnetInterface.remoteStatus.renderStatus({ parentId: "#" + id, status: "false", tooltipText: I18n["ajax_error"] });
          }
        }, vipnetInterface.remoteStatus.ajaxTimeout, id);
      }
    },

    spinnerVisibility: function(id) {
      return $("#" + id).parent().find("div[name='spinner']").css("visibility");
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
      if(e.which == 27) {
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
  lastSelectedRow: "",
  CSVSeparator: ";",
    selectRow: function(rowId) {
    if(vipnetInterface.lastSelectedRow == rowId) {
      vipnetInterface.lastSelectedRow = "";
    } else {
      vipnetInterface.lastSelectedRow = rowId;
    }
    $row = $(rowId);
    $row.toggleClass("nodes__row--selected");
    rowIdPosition = vipnetInterface.selectedRows.indexOf(rowId);
    if(rowIdPosition == -1) {
      vipnetInterface.selectedRows.push(rowId);
    } else {
      vipnetInterface.selectedRows.splice(rowIdPosition, 1);
    }
    // update badge and button
    selectedRowsLength = vipnetInterface.selectedRows.length;
    if(selectedRowsLength > 0) {
      $("#nodes__actions").removeAttr("disabled");
    } else {
      $("#nodes__actions").attr("disabled", "disabled");
    }
    $("#nodes__unselect-all").attr("data-badge", selectedRowsLength);
  },

  fillExportTextarea: function() {
    var $copyTextarea = $("#nodes__export-selected textarea");
    $copyTextarea.val("");
    vipnetInterface.selectedRows.sort(function(a,b) {
      return vipnetInterface.nodesData[a].vipnetId.localeCompare(vipnetInterface.nodesData[b].vipnetId)
    });
    var exportArray = [];
    var variant = $("#export-selected__variants div[selected='selected']").attr("name");
    if(variant == "csv") {
      var rows = Object.keys(vipnetInterface.nodesData);
      var someNodeData = vipnetInterface.nodesData[rows[0]];
      exportArray.push(Object.keys(someNodeData).join(vipnetInterface.CSVSeparator));
    }
    vipnetInterface.selectedRows.forEach(function(selectedRow) {
      var vipnetId = vipnetInterface.nodesData[selectedRow].vipnetId;
      var name = vipnetInterface.nodesData[selectedRow].name;
      if(variant == "id_space_name_newline") {
        exportArray.push(vipnetId + " " + name);
      } else if(variant == "id_comma") {
        exportArray.push(vipnetId);
      } else if(variant == "csv") {
        var CSVDataArray = [];
        vipnetInterface.nodesData[selectedRow]
        for(var prop in vipnetInterface.nodesData[selectedRow]) {
          CSVDataArray.push(vipnetInterface.nodesData[selectedRow][prop]);
        }
        exportArray.push(CSVDataArray.join(vipnetInterface.CSVSeparator));
      }
    });
    if(variant == "id_space_name_newline" || variant == "csv") {
      $copyTextarea.val(exportArray.join("\n"));
    } else if(variant == "id_comma") {
      $copyTextarea.val(exportArray.join(","));
    }
    return $copyTextarea;
  },

  shiftSelectRow: function(rowId) {
    var lastSelectedRowIndex = $(vipnetInterface.lastSelectedRow).index();
    var rowIndex = $(rowId).index();
    if(lastSelectedRowIndex == rowIndex) {
      return;
    }
    var $table = $(".nodes table")
    var $rows = $("tr", $table);
    var upperRowIndex = Math.min(lastSelectedRowIndex, rowIndex);
    var downRowIndex = Math.max(lastSelectedRowIndex, rowIndex);
    for(var i = upperRowIndex; i <= downRowIndex; i++) {
      if(i == lastSelectedRowIndex) {
        continue;
      }
      vipnetInterface.selectRow("#" + $rows.eq(i+1)[0].id);
    }
    vipnetInterface.clearSelection();
  },

  unselectAllRows: function() {
    // clone array to prevent errors causing by iterating changing object
    var selectedRows = vipnetInterface.selectedRows.slice(0);
    selectedRows.forEach(function(selectedRow) {
      vipnetInterface.selectRow(selectedRow);
    });
  },

  selectAllRows: function() {
    vipnetInterface.unselectAllRows();
    for(var id in vipnetInterface.nodesData) {
      vipnetInterface.selectRow(id);
    }
  },

  singleClick: function(e) {
    // http://stackoverflow.com/a/10390097/6376451
    // e.button == 1 for middle button
    var selection = getSelection().toString();
    if(!selection && e.button != 1) {
      return true;
    } else {
      return false;
    }
  },

  // http://stackoverflow.com/a/3169849
  clearSelection: function() {
    if (window.getSelection) {
      if (window.getSelection().empty) {
        window.getSelection().empty();
      } else if (window.getSelection().removeAllRanges) {
        window.getSelection().removeAllRanges();
      }
    } else if (document.selection) {
      document.selection.empty();
    }
  },

  showSnackbar: function(msg) {
    snackbarContainer = $("#nodes__snackbar")[0];
    var msgToShow = I18n["snackbar"][msg] || msg;
    snackbarContainer.MaterialSnackbar.showSnackbar({ message: msgToShow });
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
    if(e.shiftKey) {
      vipnetInterface.shiftSelectRow("#"  + this.id);
    } else {
      if(vipnetInterface.singleClick(e)) {
        vipnetInterface.selectRow("#"  + this.id);
      }
    }
  });

  $("#nodes__unselect-all").click(function() {
    vipnetInterface.unselectAllRows();
  });

  $("#nodes__select-all").click(function() {
    vipnetInterface.selectAllRows();
  });

  $("#nodes__export-selected").click(function() {
    if(!$("#nodes__export-selected label").attr("disabled")) {
      // http://stackoverflow.com/a/30810322
      var $copyTextarea = vipnetInterface.fillExportTextarea();
      $copyTextarea.select();
      document.execCommand("copy");
      vipnetInterface.showSnackbar("copied");
    }
  });

  $("a[data-variant]").click(function() {
    this_variant = $(this).data("variant");
    $variants = $(this).parent().find("a");
    $variants.each(function(_, variant) {
      var $div = $(variant).find("div");
      var $a = $(variant);
      if(this_variant != $a.data("variant")) {
        $div.removeAttr("selected");
        $a.css("pointer-events", "auto");
      } else {
        $div.attr("selected", "selected");
        $a.css("pointer-events", "none");
      }
    });
  });
});
