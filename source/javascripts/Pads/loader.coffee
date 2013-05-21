$.when(impamp.storage, impamp.docReady).done (storage) ->
  $('#loading-modal').modal('show')
  impamp.loadPads(storage)

$.when(impamp.padsLoaded).done ->
  $('#loading-modal').modal('hide')

impamp.loadPads = loadPads = (storage) ->
  padPromises = []
  count = 0

  $('.pad').each (i, pad) ->
    deferred = $.Deferred()
    padPromises.push(deferred)

    $pad = $(pad)
    loadPad $pad, storage, ->
      deferred.resolve()
      count += 1
      $padsLoaded.text(count)

      return

  $padsTotal = $('#loading-modal').find('#pads-total')
  $padsTotal.text(padPromises.length)

  $padsLoaded = $('#loading-modal').find('#pads-loaded')

  waiting = $.when.apply($, padPromises)
  waiting.done ->
    impamp.padsLoaded.resolve()

impamp.loadPad =  loadPad  = ($pad, storage, callback) ->
  if not storage?
    impamp.storage.done (storage) ->
      impamp.loadPad($pad, storage, callback)
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

      callback?(false)
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

    # Clear existing handlers:
    $audioElement.off 'timeupdate'
    $audioElement.off 'play'
    $audioElement.off 'pause'
    $audioElement.off 'ended'
    $audioElement.off 'error'

    $audioElement.on 'timeupdate', (e) ->
      return if audioElement.paused

      $progress_bar = $pad.find(".progress .bar")
      $progress_bar.removeClass "bar-warning"
      $progress_bar.removeClass "bar-grey"

      $progress_text = $pad.find(".progress > span")

      percent = (audioElement.currentTime / audioElement.duration) * 100
      $progress_bar.css
        width: percent + "%"

      $progress_text.text(Math.round(audioElement.duration - audioElement.currentTime))

      impamp.collaboration.timeupdate page, key, audioElement.currentTime

    $progress = $pad.find(".progress")

    $audioElement.on 'play', (e) ->
      $progress.show()
      impamp.addNowPlaying($pad)
      impamp.collaboration.play page, key, audioElement.currentTime

    pauseEndHandler = (e) ->
      $progress.hide()
      impamp.removeNowPlaying($pad)
      impamp.collaboration.pause page, key, audioElement.currentTime

    $audioElement.on 'pause', pauseEndHandler
    $audioElement.on 'ended', pauseEndHandler

    $audioElement.on 'error', (element) ->
      $pad.addClass("error")
      return true

    callback?(true)