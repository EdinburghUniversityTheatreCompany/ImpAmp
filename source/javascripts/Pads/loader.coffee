$.when(impamp.storage, impamp.docReady).done (storage) ->
  impamp.loadPads(storage)

impamp.loadPads = loadPads = (storage) ->
  $('.pad').each (i, pad) ->
    $pad = $(pad)

    loadPad($pad, storage)

impamp.loadPad =  loadPad  = ($pad, storage) ->
  if not storage?
    impamp.storage.done (storage) ->
      impamp.loadPad($pad, storage)
    return

  $pad.find(".name").text("")
  $pad.removeClass "disabled"
  $pad.removeClass "error"

  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  storage.getPad page, key, (padData) ->
    if not padData?
      $pad.addClass "disabled"
      return

    url = window.URL.createObjectURL(padData.file);
    $pad.find("audio").attr("src", url)
    $pad.find(".name").text(padData.name)

    $audioElement = $pad.find("audio")
    audioElement = $audioElement[0]
    $audioElement.on 'timeupdate', (e) ->
      $progress_bar = $pad.find(".progress .bar")

      percent = (audioElement.currentTime / audioElement.duration) * 100
      $progress_bar.css
        width: percent + "%"

    $audioElement.on 'ended', (e) ->
      $progress = $pad.find(".progress")
      $progress.hide()

    $audioElement.on 'error', (element) ->
      $pad.addClass("error")
      return true