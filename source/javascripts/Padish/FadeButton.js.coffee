$ ->
  $fadeButton = $('.padish a[data-shortcut="space"]')
  $fadeButton.click ->
    $progress = $fadeButton.find(".progress")
    $progress.show()

    $progress_bar = $progress.find(".bar")
    $progress_bar.css
      width: 0

    $('audio').each (i, elem) ->
      return if elem.paused

      $elem = $(elem)

      $elem.animate
        volume: 0
      ,
        duration: 3000
        progress: (animation, progress) ->
          $progress_bar.css
            width: (progress * 100) + "%"
        complete: ->
          elem.pause()
          elem.currentTime = 0
          elem.volume = 1;
          $pad = $(elem).closest(".pad")
          $pad.find(".progress").hide()

          $progress.hide()