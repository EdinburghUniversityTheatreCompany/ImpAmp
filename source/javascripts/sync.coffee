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

        if serverPad.name != name || serverPad.filename != filename || `serverPad.filesize != filesize`
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
        setSyncButton("exclamation-sign", "Sync Error")
    error: ->
      syncInProgress = false
      setSyncButton("exclamation-sign", "Sync Error")

# Should return a jQuery promise.
updatePad = ($pad, serverPad) ->
  updatedAt = $pad.data('updatedAt')

  if (not serverPad.updatedAt?) || (updatedAt > serverPad.updatedAt)
    return sendToServer($pad)
  else if serverPad.filename == null
    deferred = $.Deferred()

    impamp.storage.done (storage) ->
      storage.removePad impamp.pads.getPage($pad), impamp.pads.getKey($pad), ->
        impamp.loadPad($pad)
        deferred.resolve()

    return deferred.promise()
  else
    return getFromServer($pad, serverPad)

sendToServer = ($pad) ->
  deferred = $.Deferred()

  $progress = $pad.find(".progress")

  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  impamp.storage.done (storage) ->
    storage.getPad page, key, (padData) ->

      # First, upload the file
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

        # Remove the blob
        delete padData.file

        # Then send the padData
        $.ajax
          url:  config.url + "pad/#{padData.page}/#{padData.key}"
          type: "POST"
          data: padData
          error: ->
            deferred.reject()

        deferred.resolve()
        return

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

  return deferred.promise()

getFromServer = ($pad, serverPad) ->
  deferred = $.Deferred()

  $progress = $pad.find(".progress")

  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

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

    blob = oReq.response
    impamp.storage.done (storage) ->
      storage.setPad page, key, serverPad.name, blob, serverPad.filename, serverPad.filesize, ->
        impamp.loadPad($pad, storage)
        deferred.resolve()
        return
      , serverPad.updatedAt

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

impamp.sync.deletePad = deletePad = (page, key) ->
  $.ajax
    type: "DELETE",
    url:  config.url + "pad/#{page}/#{key}"

# Should return a jQuery promise.
updatePage = ($pageNav, serverPage) ->
  updatedAt = $pageNav.data('updatedAt')

  if (not serverPage.updatedAt?) || (updatedAt > serverPage.updatedAt)
    return sendPageToServer($pageNav)
  else
    deferred = $.Deferred()

    impamp.storage.done (storage) ->
      pageNo = impamp.pages.getPageNo $pageNav

      storage.setPage pageNo, serverPage.name, ->
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
        data: pageData
        error: ->
          deferred.reject()

      deferred.resolve()
      return

  return deferred.promise()

$ ->
  $('#syncBtn').click (e) ->
    $btn = $(e.currentTarget)
    if $btn.data('config.enabled') == true
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

$.when(impamp.storage, impamp.docReady).done ->
  setInterval sync, 10 * 1000