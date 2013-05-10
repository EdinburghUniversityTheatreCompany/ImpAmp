impamp.sync = {}
syncUrl = impamp.sync.url = location.protocol + "//" + location.host + "/"
syncEnabled = true

sync = ->
  if not syncUrl?
    setSyncButton("exclamation-sign", "SyncUrl not set")
    return
  return unless syncEnabled

  setSyncButton("refresh icon-spin", "Synchronising")

  $.ajax
    url: syncUrl + "impamp_server.json",
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

      syncWait = $.when.apply($, updates)
      syncWait.done ->
        setSyncButton("ok", "Sync Complete")
      syncWait.fail ->
        setSyncButton("exclamation-sign", "Sync Error")
    error: ->
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

  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  impamp.storage.done (storage) ->
    storage.getPad page, key, (padData) ->

      # First, upload the file
      oReq = new XMLHttpRequest();
      oReq.open("POST", syncUrl + "audio/" + padData.filename, true);
      oReq.setRequestHeader("Content-Type", "application/octet-stream")
      oReq.onload = (e) ->
        if not ((this.status == 200 || this.status == 304) && this.readyState == 4)
          # error
          deferred.reject()
          return

        # Remove the blob
        delete padData.file

        # Then send the padData
        $.ajax
          url:  syncUrl + "pad/#{padData.page}/#{padData.key}"
          data: padData
          error: ->
            deferred.reject()

        deferred.resolve()
        return

      oReq.send(padData.file);

  return deferred.promise()

getFromServer = ($pad, serverPad) ->
  deferred = $.Deferred()

  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  oReq = new XMLHttpRequest();
  oReq.open("GET", syncUrl + "audio/#{serverPad.filename}", true);
  oReq.responseType = "blob";
  oReq.onload = (e) ->
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
  oReq.send();

  return deferred.promise()

impamp.sync.deletePad = deletePad = (page, key) ->
  $.ajax
    type: "DELETE",
    url:  syncUrl + "pad/#{page}/#{key}"

$ ->
  $('#syncBtn').click (e) ->
    $btn = $(e.currentTarget)
    if $btn.data('sync-enabled') == true
      syncEnabled = false
      setSyncButton("remove-sign", "Sync Disabled")
      $btn.data('sync-enabled', false)
    else
      syncEnabled = true
      setSyncButton("time", "Waiting for Sync")
      $btn.data('sync-enabled', true)

setSyncButton = (icon, text) ->
  $('#syncBtn').html """
  <i class="icon-#{icon}"></i> #{text}
                     """

$.when(impamp.storage, impamp.docReady).done ->
  setInterval sync, 10 * 1000