$ ->
  $fadeButton = $('.padish a[data-shortcut="space"]')
  $fadeButton.click ->
    $progress = $fadeButton.find(".progress")
    $progress.show()

    $progress_bar = $progress.find(".bar")
    $progress_bar.css
      width: 0

    $progress_text = $progress.find("span")

    fading = false

    $('audio').each (i, elem) ->
      return if elem.paused

      fading = true

      $elem = $(elem)
      $elem.animate
        volume: 0
      ,
        duration: 3000
        progress: (animation, progress) ->
          $progress_bar.css
            width: (progress * 100) + "%"

          $progress_text.text(Math.round(3 - 3 * progress))
        complete: ->
          elem.pause()
          elem.currentTime = 0
          elem.volume = 1;

          $progress.hide()

    if fading == false
      $progress.hide()