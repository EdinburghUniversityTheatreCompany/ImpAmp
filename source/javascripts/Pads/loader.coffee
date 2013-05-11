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

    if not padData?
      $pad.addClass "disabled"
      $pad.removeData('name', null)
      $pad.removeData('filename', null)
      $pad.removeData('updatedAt', null)
      $pad.removeData('filesize', null)

      return

    $pad.data('name', padData.name)
    $pad.data('filename', padData.filename)
    $pad.data('updatedAt', padData.updatedAt)
    $pad.data('filesize', padData.filesize)

    url = window.URL.createObjectURL(padData.file);
    $pad.find("audio").attr("src", url)
    $pad.find(".name").text(padData.name)

    $audioElement = $pad.find("audio")
    audioElement = $audioElement[0]
    $audioElement.on 'timeupdate', (e) ->
      $progress_bar = $pad.find(".progress .bar")
      $progress_bar.removeClass "bar-warning"

      percent = (audioElement.currentTime / audioElement.duration) * 100
      $progress_bar.css
        width: percent + "%"

    $audioElement.on 'ended', (e) ->
      $progress = $pad.find(".progress")
      $progress.hide()

    $audioElement.on 'error', (element) ->
      $pad.addClass("error")
      return true