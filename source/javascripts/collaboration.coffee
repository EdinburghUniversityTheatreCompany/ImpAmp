impamp = window.impamp
impamp.collaboration = {}

errorCount = 0

es = new EventSource('/c/stream')
es.onerror = ->
  errorCount += 1
  if errorCount > 10
    # Give up. It's not happening. Probably because the server doesn't
    # support it.
    es.close()

es.onmessage = (e) ->
  data = JSON.parse(e.data)

  data.key = impamp.pads.escapeKey(data.key)

  # Find the pad
  $page = $("#page_#{data.page}")
  $pad = $page.find(".pad [data-shortcut='#{data.key}']").closest(".pad")

  audioElement = $pad.find("audio")[0]

  return unless audioElement.paused

  $progress = $pad.find(".progress")
  $progress_bar = $pad.find(".progress .bar")

  switch data.type
    when "play", "timeupdate"
      if $(".now-playing-item[data-playId='#{data.playId.replace("\\", "\\\\")}']").length == 0
        impamp.addNowCollaborating($pad, data.playId)
        setTimeout( ->
          # If it doesn't get the stop message, fade out 5 seconds after it
          # was meant to.
          $progress.hide()
          impamp.removeNowCollaborating(data.playId)
        , (audioElement.duration + 5) * 1000)

      $progress_bar.addClass "bar-grey"
      $progress.show()

      $progress_bar.css
        width: impamp.pads.getPercent($pad, audioElement, data.time) + "%"

      $progress_text = $pad.find(".progress > span")
      $progress_text.text impamp.pads.getRemaining($pad, audioElement, data.time)

      impamp.updateNowCollaborating($pad, data.playId, data.time)

    when "pause"
      $progress.hide()
      impamp.removeNowCollaborating(data.playId)

impamp.collaboration.play = (page, key, playId, time) ->
  $.post "/c/play",
    page: page
    key:  key
    playId: playId
    time: time

lastUpdate = null
impamp.collaboration.timeupdate = (page, key, playId, time) ->
  now = new Date()

  # Update max twice a second
  return if (now - lastUpdate) < 500
  lastUpdate = now

  $.post "/c/timeupdate",
    page: page
    key:  key
    playId: playId
    time: time

impamp.collaboration.pause = (page, key, playId, time) ->
  $.post "/c/pause",
    page: page
    key:  key
    playId: playId
    time: time