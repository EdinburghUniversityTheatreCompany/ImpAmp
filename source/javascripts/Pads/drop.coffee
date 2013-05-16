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
      e.originalEvent.dataTransfer.setData "application/x-impamp-move", "#{impamp.pads.getPage $pad} #{impamp.pads.getKey $pad}"

    $pad.on "dragover", ->
      #add hover class when drag over
      $pad.addClass "hover"
      return false

    $pad.on "dragleave", ->
      #remove hover class when drag out
      $pad.removeClass "hover"
      return false

    $pad.on "drop", (e) ->
      #prevent browser from open the file when drop off
      e.stopPropagation()
      e.preventDefault()
      $pad.removeClass "hover"

      ia_move_data = e.originalEvent.dataTransfer.getData("application/x-impamp-move");
      unless ia_move_data == ""
        movePad($pad, ia_move_data)
        return false

      #retrieve uploaded files data
      files = e.originalEvent.dataTransfer.files
      if files.length > 0
        file = files[0]
        setPadFile($pad, file)

      return false

    return

setPadFile = ($pad, file) ->
  page = impamp.pads.getPage $pad
  key  = impamp.pads.getKey  $pad
  name = file.name

  impamp.storage.done (storage) ->
    storage.setPad page, key, name, file, file.name, file.size, ->
      impamp.loadPad($pad)

movePad = ($new_pad, ia_move_data) ->
  old_page = ia_move_data.split(" ")[0]
  old_key  = ia_move_data.split(" ")[1]

  $old_pad = $(".pad-page.active a[data-shortcut='#{old_key}']").closest(".pad")
  $old_pad.addClass "disabled"

  $old_pad.find(".name").text "Please Wait..."
  $new_pad.find(".name").text "Please Wait..."

  new_page = impamp.pads.getPage $new_pad
  new_key  = impamp.pads.getKey  $new_pad

  impamp.storage.done (storage) ->
    storage.getPad old_page, old_key, (padData) ->
      storage.setPad new_page, new_key, padData.name, padData.file, padData.filename, padData.filesize, ->
        impamp.sync.deletePad old_page, old_key
        storage.removePad old_page, old_key, ->
          impamp.loadPad($old_pad)

        impamp.loadPad($new_pad)

