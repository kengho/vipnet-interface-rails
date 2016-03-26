# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $("button[data-close-announcement]").click (e) ->
    e.preventDefault()
    close_announcement($(this).data("close-announcement"))

# hides button and shows spinner on click
$ ->
  $("a[data-replace-link-by-spinner]").click (e) ->
    $(this).find("div[name='button']")
      .css({
        "opacity" : "0",
        "visibility" : "hidden"
      });
    $(this).parent().find("div[name='spinner']")
      .css({
        "opacity" : "1",
        "visibility" : "visible",
        "z-index" : "400"
      });

# adds "format: 'js'" (just '.js' to href) if (obviously) js is enabled
$ ->
  $("a[data-remote]").each (i, e) =>
    $(e).attr("href", $(e).attr("href") + ".js");

hide_tooltip = (x) ->
  $(x)
    .css("z-index", "0")
    .css("display", "none");

# hide fullscreen tooltip by clicking outside
$ ->
  $("div[data-close-onclick]").click (e) ->
    hide_tooltip($(this))

# hide all fullscreen tooltips by esc
$ ->
  $(document).keyup (e) ->
    if e.which is 27
      $("div[data-close-onclick]").each (i, e) =>
        hide_tooltip($(e))

# dont hide fullscreen tooltip by clicking inside
$ ->
  $("div[data-close-onclick] div").click (e) ->
    e.stopPropagation();

# show fullscreen tooltip when click on more button
$ ->
  $("span[data-fullscreen-tooltip-key]").click (e) ->
    $("#fullscreen-tooltip__" + $(this).data("fullscreen-tooltip-key"))
      .css("z-index", "1000")
      .css("display", "table-cell");
