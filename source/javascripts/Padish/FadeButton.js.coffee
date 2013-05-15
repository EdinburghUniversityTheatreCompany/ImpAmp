$ ->
  $('.padish a[data-shortcut="space"]').click ->
    $('audio').each (i, elem) ->
      return if elem.paused

      $elem = $(elem)

      $elem.animate
        volume: 0
      , 3000
      , ->
        elem.pause()
        elem.currentTime = 0
        elem.volume = 1;
        $pad = $(elem).closest(".pad")
        $pad.find(".progress").hide()