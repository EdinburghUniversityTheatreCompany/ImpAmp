config         = {}
config.url     = location.protocol + "//" + location.host + "/"
config.enabled = true

impamp.sync = config

syncInProgress = false

sync = ->
  if not config.url?
    setSyncButton("exclamation-sign", "SyncUrl not set")
    return

  return unless config.enabled
  return if syncInProgress

  syncInProgress = true
  setSyncButton("refresh icon-spin", "Synchronising")

  $.ajax
    url: config.url + "impamp_server.json",
    type: "GET",
    xhrFields:
      withCredentials: true
    success: (data) ->
      updates = []
      $('.pad').each (i, pad) ->
        $pad = $(pad)

        page_no = impamp.pads.getPage $pad
        key     = impamp.pads.getKey  $pad

        serverPage = data.pages[page_no] || {}
        serverPad  = serverPage[key] || {}

        name      = $pad.data('name')
        filename  = $pad.data('filename')
        filesize  = $pad.data('filesize')
        updatedAt = $pad.data('updatedAt')
        startTime = $pad.data('startTime')
        endTime   = $pad.data('endTime')

        if serverPad.name != name || serverPad.filename != filename || `serverPad.filesize != filesize` || `serverPad.startTime != startTime` || `serverPad.endTime != endTime`
          updates.push updatePad($pad, serverPad)
        else if serverPad.filename? && `serverPad.updatedAt != updatedAt`
          updates.push updatePad($pad, serverPad)

      $('.page-nav [href^="#page"]').each (i, pageNav) ->
        $pageNav = $(pageNav)

        pageNo = impamp.pages.getPageNo $pageNav

        serverPage = data.pages[pageNo] || {}

        name = $pageNav.data("name")

        if serverPage.name != name
          updates.push updatePage($pageNav, serverPage)

      syncWait = $.when.apply($, updates)
      syncWait.done ->
        syncInProgress = false
        setSyncButton("ok", "Sync Complete")
      syncWait.fail ->
        syncInProgress = false
        setSyncButton("exclamation-sign", "Sync Error: can't update server")
    error: ->
      syncInProgress = false
      setSyncButton("exclamation-sign", "Sync Error: Cant Reach Server")

# Should return a jQuery promise.
updatePad = ($pad, serverPad) ->
  updatedAt = $pad.data('updatedAt')

  if (not serverPad.updatedAt?) || (updatedAt > serverPad.updatedAt)
    return sendToServer($pad)
  else
    return getFromServer($pad, serverPad)

sendToServer = ($pad) ->
  deferred = $.Deferred()

  $progress = $pad.find(".progress")

  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  impamp.storage.done (storage) ->
    storage.getPad page, key, (padData) ->

      sendServerPad = ->
        # Remove the blob
        delete padData.file

        # Then send the padData
        $.ajax
          url:  config.url + "pad/#{padData.page}/#{keyURI(padData.key)}"
          type: "POST"
          data: JSON.stringify(padData)
          error: ->
            deferred.reject()

        deferred.resolve()
        return

      # Fetch the file first, unless the file is null
      if padData.filename == null
        sendServerPad()
        return

      oReq = new XMLHttpRequest();
      oReq.open("POST", config.url + "audio/" + padData.filename, true);
      oReq.setRequestHeader("Content-Type", "application/octet-stream")

      oReq.onload = (e) ->
        # Whatever happened, reset the progress bar
        $progress.hide()

        if not ((this.status == 200 || this.status == 304) && this.readyState == 4)
          # error
          deferred.reject()
          return

        sendServerPad()

      oReq.onerror = (e) ->
        deferred.reject()

      oReq.upload.addEventListener 'progress'
      , (e) ->
        $audioElement = $pad.find("audio")
        audioElement = $audioElement[0]
        return unless audioElement.paused

        # This could possibly be tidied up, but since play events will
        # hide the progress bar, this is easiest.
        $progress.show()
        $progress_bar = $pad.find(".progress .bar")
        $progress_bar.addClass "bar-warning"

        percent = (e.loaded / e.total) * 100
        $progress_bar.css
          width: percent + "%"
      , false

      oReq.send(padData.file);
      return

  return deferred.promise()

getFromServer = ($pad, serverPad) ->
  deferred = $.Deferred()

  $progress = $pad.find(".progress")

  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  loadServerPad = ->
    impamp.storage.done (storage) ->
      storage.setPad page, key, serverPad, ->
        impamp.loadPad($pad, storage)
        deferred.resolve()
        return
      , serverPad.updatedAt

  # Fetch the file first, unless the file is null
  if serverPad.filename == null
    serverPad.file = null
    loadServerPad()
    return deferred.promise()

  oReq = new XMLHttpRequest();
  oReq.open("GET", config.url + "audio/#{serverPad.filename}", true);
  oReq.responseType = "blob";
  oReq.onload = (e) ->
    # Whatever happened, reset the progress bar
    $progress.hide()

    if not ((this.status == 200 || this.status == 304) && this.readyState == 4)
      # error
      deferred.reject()
      return

    serverPad.file = oReq.response

    loadServerPad()

  oReq.onerror = (e) ->
    deferred.reject()

  oReq.addEventListener 'progress'
    , (e) ->
      # This could possibly be tidied up, but since play events will
      # hide the progress bar, this is easiest.
      $progress.show()
      $progress_bar = $pad.find(".progress .bar")
      $progress_bar.addClass "bar-warning"

      percent = (e.loaded / e.total) * 100
      $progress_bar.css
        width: percent + "%"
    , false

  oReq.send();

  return deferred.promise()

# Should return a jQuery promise.
updatePage = ($pageNav, serverPage) ->
  updatedAt = $pageNav.data('updatedAt')

  if (not serverPage.updatedAt?) || (updatedAt > serverPage.updatedAt)
    return sendPageToServer($pageNav)
  else
    deferred = $.Deferred()

    impamp.storage.done (storage) ->
      pageNo = impamp.pages.getPageNo $pageNav

      storage.setPage pageNo, serverPage, ->
        impamp.loadPage($pageNav)
        deferred.resolve()
      , serverPage.updatedAt

    return deferred.promise()

sendPageToServer = ($pageNav) ->
  deferred = $.Deferred()

  pageNo = impamp.pages.getPageNo $pageNav

  impamp.storage.done (storage) ->
    storage.getPage pageNo, (pageData) ->

      $.ajax
        url:  config.url + "page/#{pageNo}"
        type: "POST"
        data: JSON.stringify(pageData)
        error: ->
          deferred.reject()

      deferred.resolve()
      return

  return deferred.promise()

keyURI = (key) ->
  # Bit nasty. But it works...
  if key == "."
    return "period"

  if key == "/"
    return "slash"

  return encodeURIComponent(key)

$ ->
  $('#syncBtn').click (e) ->
    $btn = $(e.currentTarget)
    if config.enabled == true
      config.enabled = false
      setSyncButton("remove-sign", "Sync Disabled")
      $btn.data('config.enabled', false)
    else
      config.enabled = true
      setSyncButton("time", "Waiting for Sync")
      $btn.data('config.enabled', true)

impamp.setSyncButton = setSyncButton = (icon, text) ->
  $('#syncBtn').html """
  <i class="icon-#{icon}"></i> #{text}
                     """

$.when(impamp.padsLoaded).done ->
  setInterval sync, 10 * 1000