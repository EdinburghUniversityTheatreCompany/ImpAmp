$ ->
  $('.pad a').click (e) ->
    e.preventDefault()

    $pad = $(e.currentTarget).closest(".pad")
    return if $pad.hasClass("error") || $pad.hasClass("disabled")

    if e.ctrlKey
      renamePad($pad)
    else
      playPausePad($pad)

    return false

playPausePad = ($pad) ->
  audio = $pad.find("audio")[0]
  $progress = $pad.find(".progress")

  if audio.paused
    audio.play()
  else
    # Playing. Stop and reset
    audio.pause()
    audio.currentTime = 0

renamePad = ($pad) ->
  $modal = nameChangeModal()

  $('#renameInput').val($pad.data("name"))
  $modal.find('.modal-confirm').click (e) ->
    e.preventDefault()
    newName = $('#renameInput').val()

    page = impamp.pads.getPage $pad
    key  = impamp.pads.getKey  $pad

    impamp.storage.done (storage) ->
      storage.setPad page, key, { name: newName }, ->
        impamp.loadPad($pad)
        $modal.modal('hide')

    return false

nameChangeModal = ->
  title = "Rename Pad"
  body  = """
          <input id="renameInput" type="text">
          """

  return impamp.showModal(title, body, "Rename")