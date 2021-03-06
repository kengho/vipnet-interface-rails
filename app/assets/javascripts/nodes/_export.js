vipnetInterface.nodes.export = {
  data: {},
  currentPageVids: [],
  lastSelectedRowVid: null,
  CSVSeparator: ";",

  updateData: function(data) {
    // currentPageVids == ["0x1a0e0001", "0x1a0e0002", ...]
    vipnetInterface.nodes.export.currentPageVids = Object.keys(data)

    // "data" is a jsoned object passed from NodesController#load.
    // "vipnetInterface.nodes.export.data" is the stored data.
    // This function
    // 1) removes dublicates from new "data",
    // 2) removes non-selected rows from stored "data"
    // (if we moving thought pages we don't need nodes on pages we leave anymore,
    // unless we selected them),
    // 3) and merges new "data" into stored one.
    // http://stackoverflow.com/a/18202926/6376451
    Object.keys(vipnetInterface.nodes.export.data).forEach(function(vid, _) {
      if(vipnetInterface.nodes.export.data[vid].selected) {
        delete data[vid];
      } else {
        delete vipnetInterface.nodes.export.data[vid];
      }
    });

    Object.assign(vipnetInterface.nodes.export.data, data);
  },

  toggleSelectRow: function(vid) {
    var $row = vipnetInterface.nodes.row(vid);
    var selected = vipnetInterface.nodes.export.data[vid].selected;
    vipnetInterface.nodes.export.data[vid].selected = !selected;
    if(!selected) {
      vipnetInterface.nodes.export.lastSelectedRowVid = vid;
    }
    $row.toggleClass("nodes__row--selected");
    vipnetInterface.nodes.export.updateBadge();
  },

  selectRow: function(vid) {
    var $row = vipnetInterface.nodes.row(vid);
    vipnetInterface.nodes.export.data[vid].selected = true;
    vipnetInterface.nodes.export.lastSelectedRowVid = vid;
    $row.addClass("nodes__row--selected");
    vipnetInterface.nodes.export.updateBadge();
  },

  unSelectRow: function(vid) {
    var $row = vipnetInterface.nodes.row(vid);
    vipnetInterface.nodes.export.data[vid].selected = false;
    $row.removeClass("nodes__row--selected");
    vipnetInterface.nodes.export.updateBadge();
  },

  unselectAllRows: function() {
    Object.keys(vipnetInterface.nodes.export.data).forEach(function(vid, _) {
      vipnetInterface.nodes.export.unSelectRow(vid);

      // Remove all not current data.
      if($.inArray(vid, vipnetInterface.nodes.export.currentPageVids) == -1) {
        delete vipnetInterface.nodes.export.data[vid];
      }
    });
  },

  selectAllRows: function() {
    Object.keys(vipnetInterface.nodes.export.data).forEach(function(vid, _) {
      vipnetInterface.nodes.export.selectRow(vid);
    });
  },

  shiftSelectRow: function(vid) {
    var lastSelectedRowVid = vipnetInterface.nodes.export.lastSelectedRowVid;
    if(vid == lastSelectedRowVid) { return; }
    var $rows = $(".nodes__row", ".nodes");
    var start = false;
    var end = false;
    $rows.each(function(_, row) {
      var currentRowVid = $(row).data("vid")
      if([vid, lastSelectedRowVid].includes(currentRowVid)) {
        if(start) {
          end = true;
        } else {
          start = true;
        }
      }
      if(start && !end) {
        vipnetInterface.nodes.export.selectRow(currentRowVid);
      }
    });
    vipnetInterface.nodes.export.selectRow(vid);
    vipnetInterface.clearSelection();
  },

  updateBadge: function() {
    var selectedCounter = 0;
    Object.keys(vipnetInterface.nodes.export.data).forEach(function(vid, _) {
      if(vipnetInterface.nodes.export.data[vid].selected) {
        selectedCounter++;
      }
    });
    if(selectedCounter == 0) {
      $("#header__actions").attr("disabled", "disabled");
    } else {
      $("#header__actions").removeAttr("disabled");
    }
    $("#actions__unselect-all").attr("data-badge", selectedCounter);
  },

  exportData: function() {
    // vipnetInterface.nodes.export.data => selectedRowsDataArray
    // {{ vid1: { name: ..., ... }, { vid2: { name: ..., ... }, ...}
    // =>
    // [{ vid: vid1, name: ...}, [{ vid: vid2, name: ...}, ...]
    // sorted by vids and only for selected rows ("selected" key is omitted)
    var selectedRowsDataArray = Object.keys(vipnetInterface.nodes.export.data).map(function(vid) {
      if(vipnetInterface.nodes.export.data[vid].selected) {
        var dataObj = {};
        Object.keys(vipnetInterface.nodes.export.data[vid]).forEach(function(dataProp) {
          if(dataProp != "selected") {
            dataObj[dataProp] = vipnetInterface.nodes.export.data[vid][dataProp];
          }
        });
        return Object.assign({ vid: vid }, dataObj);
      }
    }).filter(function(e) { return e != undefined })
      .sort(function(a, b) {
        return a.vid.localeCompare(b.vid)
      });

    var variant = $(".export-selected-variant input[name='export_selected_variant']:checked").val();
    var exportArray = [];
    if(variant == "csv") {
      exportArray.push(Object.keys(selectedRowsDataArray[0]).join(vipnetInterface.nodes.export.CSVSeparator));
    }

    selectedRowsDataArray.forEach(function(data) {
      if(variant == "id_space_name_newline") {
        exportArray.push(data.vid + " " + data.name);
      } else if(variant == "id_comma") {
        exportArray.push(data.vid);
      } else if(variant == "csv") {
        exportArray.push(
          Object.keys(data).map(function(prop) {
            return data[prop];
          }).join(vipnetInterface.nodes.export.CSVSeparator));
      }
    });

    if(["id_space_name_newline", "csv"].includes(variant)) {
      return exportArray.join("\n");
    } else if(variant == "id_comma") {
      return exportArray.join(",");
    }
  },
}
