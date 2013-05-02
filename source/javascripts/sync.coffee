syncUrl = impamp.syncUrl = location.protocol + "//" + location.host + "/"

sync = ->
  return unless syncUrl?
  $.ajax
    url: syncUrl + "impamp_server.json",
    xhrFields:
      withCredentials: true
    success: (data) ->
      $('.pad').each (i, pad) ->
        $pad = $(pad)

        page_no = impamp.pads.getPage $pad
        key     = impamp.pads.getKey  $pad

        serverPage = data.pages[page_no] || {}
        serverPad  = serverPage[key] || {}

        name      = $pad.data('name')
        filename  = $pad.data('filename')
        filehash  = $pad.data('filehash')
        updatedAt = $pad.data('updatedAt')

        if serverPad.name != name || serverPad.filename != filename
          updatePad($pad, serverPad)
        else if serverPad.filehash != filehash && filehash != "" # Don't keep updating if the hash hasn't been calculated yet.
          updatePad($pad, serverPad)

updatePad = ($pad, serverPad) ->
  updatedAt = $pad.data('updatedAt')

  if (not serverPad.updatedAt?) || (updatedAt > serverPad.updatedAt)
    sendToServer($pad)
  else
    getFromServer($pad, serverPad)

sendToServer = ($pad) ->
  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad
  filehash = $pad.data('filehash')

  # Ensure the file has been hashed...
  return unless filehash?

  impamp.storage.done (storage) ->
    storage.getPad page, key, (padData) ->

      # First, upload the file
      oReq = new XMLHttpRequest();
      oReq.open("POST", syncUrl + "audio/" + padData.filename, true);
      oReq.setRequestHeader("Content-Type", "application/octet-stream")
      oReq.onload = (oEvent) ->

        # Remove the blob
        delete padData.file
        padData.filehash = filehash

        # Then send the padData
        $.post (syncUrl + "pad/#{padData.page}/#{padData.key}"), padData
        return

      oReq.send(padData.file);

getFromServer = ($pad, serverPad) ->
  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  oReq = new XMLHttpRequest();
  oReq.open("GET", syncUrl + "audio/#{serverPad.filename}", true);
  oReq.responseType = "blob";
  oReq.onload = (e) ->
    blob = oReq.response
    impamp.storage.done (storage) ->
      storage.setPad page, key, serverPad.name, blob, serverPad.filename, ->
        impamp.loadPad($pad, storage)
      , serverPad.updatedAt
  oReq.send();


$.when(impamp.storage, impamp.docReady).done ->
  setInterval sync, 10 * 1000