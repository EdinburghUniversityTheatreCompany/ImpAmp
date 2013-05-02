impamp.sync = {}
syncUrl = impamp.sync.url = location.protocol + "//" + location.host + "/"

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
        filesize  = $pad.data('filesize')
        updatedAt = $pad.data('updatedAt')

        if serverPad.name != name || serverPad.filename != filename || `serverPad.filesize != filesize`
          updatePad($pad, serverPad)
        else if serverPad.filename? && `serverPad.updatedAt != updatedAt`
          updatePad($pad, serverPad)

updatePad = ($pad, serverPad) ->
  updatedAt = $pad.data('updatedAt')

  if (not serverPad.updatedAt?) || (updatedAt > serverPad.updatedAt)
    sendToServer($pad)
  else if serverPad.filename == null
    impamp.storage.done (storage) ->
      storage.removePad impamp.pads.getPage($pad), impamp.pads.getKey($pad), ->
        impamp.loadPad($pad)
  else
    getFromServer($pad, serverPad)

sendToServer = ($pad) ->
  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  impamp.storage.done (storage) ->
    storage.getPad page, key, (padData) ->

      # First, upload the file
      oReq = new XMLHttpRequest();
      oReq.open("POST", syncUrl + "audio/" + padData.filename, true);
      oReq.setRequestHeader("Content-Type", "application/octet-stream")
      oReq.onload = (e) ->
        return unless (this.status == 200 || this.status == 304) && this.readyState == 4

        # Remove the blob
        delete padData.file

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
    return unless (this.status == 200 || this.status == 304) && this.readyState == 4

    blob = oReq.response
    impamp.storage.done (storage) ->
      storage.setPad page, key, serverPad.name, blob, serverPad.filename, serverPad.filesize, ->
        impamp.loadPad($pad, storage)
      , serverPad.updatedAt
  oReq.send();

impamp.sync.deletePad = deletePad = (page, key) ->
  $.ajax
    type: "DELETE",
    url:  syncUrl + "pad/#{page}/#{key}"

$.when(impamp.storage, impamp.docReady).done ->
  setInterval sync, 10 * 1000