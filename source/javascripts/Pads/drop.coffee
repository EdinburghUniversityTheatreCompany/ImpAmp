impamp.locked = localStorage["locked"] || false

if typeof impamp.locked == "string"
  impamp.locked = JSON.parse impamp.locked

$ ->
  # prevent browser from opening the file if we missed a pad.
  $(window).on "dragover", (e) ->
    e.preventDefault()
    return false
  $(window).on "drop", (e) ->
    e.stopPropagation()
    e.preventDefault()
    return false

  $('.pad').each (i, pad) ->
    $pad = $(pad)

    $pad.on "dragstart", (e) ->
      if impamp.locked
        e.preventDefault()
        flashLock()

        return false

      page = impamp.pads.getPage $pad
      key  = impamp.pads.getKey  $pad

      evt = e.originalEvent
      evt.dataTransfer.setData "application/x-impamp-move", "#{page} #{key}"

      # For file download:
      evt.dataTransfer.setData("DownloadURL", $pad.data("downloadurl"));

    $pad.on "dragover", ->
      #add hover class when drag over
      $pad.addClass "hover"
      return false

    $pad.on "dragleave", ->
      #remove hover class when drag out
      $pad.removeClass "hover"
      return false

    $pad.on "drop", (e) ->
      # Prevent browser from opening the file on drop.
      e.stopPropagation()
      e.preventDefault()
      $pad.removeClass "hover"

      # if locked, flash the lock button and return
      if impamp.locked
        flashLock()
        return false

      ia_move_data = e.originalEvent.dataTransfer.getData("application/x-impamp-move");
      unless ia_move_data == ""
        movePad($pad, ia_move_data)
        return false

      files = e.originalEvent.dataTransfer.files
      if files.length > 0
        file = files[0]
        setPadFile($pad, file)

      return false

    return

setPadFile = ($pad, file) ->
  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad

  impamp.storage.done (storage) ->
    storage.setPad page, key,
      name: file.name
      file: file
      filename: file.name
      filesize: file.size
    , ->
      impamp.loadPad($pad)

movePad = ($new_pad, ia_move_data) ->
  old_page = ia_move_data.split(" ")[0]
  old_key  = ia_move_data.split(" ")[1]

  new_page = impamp.pads.getPage $new_pad
  new_key  = impamp.pads.getKey  $new_pad

  if old_page == new_page && old_key == new_key
    # Accident. Get out.
    return

  $old_pad = $(".pad-page.active a[data-shortcut='#{impamp.pads.escapeKey(old_key)}']").closest(".pad")

  $old_pad.addClass "disabled"
  $old_pad.find(".name").text "Please Wait..."
  $new_pad.find(".name").text "Please Wait..."

  impamp.storage.done (storage) ->
    # First, get rid if there is a pad there already.
    storage.clearPad new_page, new_key, ->
      # Then update the pad.
      storage.setPad old_page, old_key,
        page: new_page
        key:  new_key
      , ->
        impamp.loadPad($old_pad)
        impamp.loadPad($new_pad)

$ ->
  $lockBtn = $('#lockBtn')
  $icon    = $lockBtn.find "i"

  updateLock(impamp.locked)

  $lockBtn.click ->
    impamp.locked = not impamp.locked
    localStorage["locked"] = impamp.locked

    updateLock()

updateLock = ->
  $lockBtn = $('#lockBtn')
  $icon    = $lockBtn.find "i"

  if impamp.locked == true
    # Lock
    $icon.removeClass "icon-unlock"
    $lockBtn.addClass "active"
    $icon.addClass    "icon-lock"
  else
    # Unlock
    $icon.removeClass "icon-lock"
    $lockBtn.removeClass "active"
    $icon.addClass    "icon-unlock"

flashCount = 0
flashLock = ->
  $lockBtn = $('#lockBtn')

  flashCount += 1;
  if flashCount >= 2
    $lockBtn.popover
      title:     "ImpAmp Locked"
      content:   "Click the lock icon to allow pads to be changed or moved."
      placement: "bottom"
    $lockBtn.popover("show")
    $lockBtn.on "click", ->
      $lockBtn.popover("hide")
      flashCount = -1

  $lockBtn.fadeOut(100).fadeIn(100).fadeOut(100).fadeIn(100)