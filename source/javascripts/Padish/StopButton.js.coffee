$ ->
  $('.padish a[data-shortcut="esc"]').click ->
    $('audio').each (i, elem) ->
      return if elem.paused

      elem.pause()
      elem.currentTime = 0
      $pad = $(elem).closest(".pad")
      $pad.find(".progress").hide()