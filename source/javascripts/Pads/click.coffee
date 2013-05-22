$ ->
  $('.pad a').click (e) ->
    e.preventDefault()

    $pad = $(e.currentTarget).closest(".pad")
    return if $pad.hasClass("error") || $pad.hasClass("disabled")

    if e.ctrlKey
      impamp.editPad($pad)
    else
      playPausePad($pad)

    return false

playPausePad = ($pad) ->
  audio = $pad.find("audio")[0]
  $progress = $pad.find(".progress")

  if audio.paused
    audio.currentTime = $pad.data("startTime") || 0
    audio.play()
  else
    # Playing. Stop.
    audio.pause()