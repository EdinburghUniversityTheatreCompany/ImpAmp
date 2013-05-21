impamp = window.impamp
impamp.collaboration = {}

es = new EventSource('/c/stream');
es.onmessage = (e) ->
  data = JSON.parse(e.data)

  # Escaping woes
  data.key = "\\\\" if data.key == "\\"

  # Find the pad
  $page = $("#page_#{data.page}")
  $pad = $page.find(".pad [data-shortcut='#{data.key}']").closest(".pad")

  audioElement = $pad.find("audio")[0]

  return unless audioElement.paused

  $progress = $pad.find(".progress")
  $progress_bar = $pad.find(".progress .bar")

  switch data.type
    when "play", "timeupdate"
      $progress_bar.addClass "bar-grey"
      $progress.show()

      percent = (data.time / audioElement.duration) * 100
      $progress_bar.css
        width: percent + "%"

      $progress_text = $pad.find(".progress > span")
      $progress_text.text(Math.round(audioElement.duration - data.time))

    when "pause"
      $progress.hide()

impamp.collaboration.play = (page, key, time) ->
  $.post "/c/play",
    page: page
    key:  key
    time: time

lastUpdate = null
impamp.collaboration.timeupdate = (page, key, time) ->
  now = new Date()

  # Update max once a second
  return if (now - lastUpdate) < 1000
  lastUpdate = now

  $.post "/c/timeupdate",
    page: page
    key:  key
    time: time

impamp.collaboration.pause = (page, key, time) ->
  $.post "/c/pause",
    page: page
    key:  key
    time: time