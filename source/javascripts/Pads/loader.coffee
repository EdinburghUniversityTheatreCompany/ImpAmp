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

  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  storage.getPad page, key, (padData) ->
    $pad.find(".name").text("")
    $pad.removeClass "disabled"
    $pad.removeClass "error"

    $pad.data('updatedAt', padData.updatedAt) if (padData? && padData.updatedAt?)

    if (not padData?) || (not padData.file?)
      $pad.addClass "disabled"
      $pad.removeData('name', null)
      $pad.removeData('filename', null)
      $pad.removeData('filesize', null)
      $pad.removeAttr('data-downloadurl')

      return

    $pad.data('name', padData.name)
    $pad.data('filename', padData.filename)
    $pad.data('filesize', padData.filesize)
    $pad.attr('data-downloadurl', "application/octet-stream:#{padData.filename}:#{window.URL.createObjectURL(padData.file)}")

    url = window.URL.createObjectURL(padData.file);
    $pad.find("audio").attr("src", url)
    $pad.find(".name").text(padData.name)

    $audioElement = $pad.find("audio")
    audioElement = $audioElement[0]
    $audioElement.on 'timeupdate', (e) ->
      $progress_bar = $pad.find(".progress .bar")
      $progress_bar.removeClass "bar-warning"

      $progress_text = $pad.find(".progress > span")

      percent = (audioElement.currentTime / audioElement.duration) * 100
      $progress_bar.css
        width: percent + "%"

      $progress_text.text(Math.round(audioElement.duration - audioElement.currentTime))

    $progress = $pad.find(".progress")

    $audioElement.on 'play', (e) ->
      $progress.show()
      impamp.addNowPlaying($pad)

    pauseEndHandler = (e) ->
      $progress.hide()
      impamp.removeNowPlaying($pad)

    $audioElement.on 'pause', pauseEndHandler
    $audioElement.on 'ended', pauseEndHandler

    $audioElement.on 'error', (element) ->
      $pad.addClass("error")
      return true