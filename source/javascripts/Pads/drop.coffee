$ ->
  $('.pad').each (i, pad) ->
    $pad = $(pad)

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

      #retrieve uploaded files data
      files = e.originalEvent.dataTransfer.files
      count = files.length;

      if count > 0
        file = files[0]
        page = impamp.pads.getPage $pad
        key  = impamp.pads.getKey  $pad
        name = file.name

        impamp.storage.done (storage) ->
          storage.setPad page, key, name, file, file.name, file.size, ->
            impamp.loadPad($pad)

      return false

    return