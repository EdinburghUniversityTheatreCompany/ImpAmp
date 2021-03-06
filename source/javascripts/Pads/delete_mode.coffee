$ ->
  $deleteMode = $('#delete_mode')
  $deleteMode.click ->
    if $deleteMode.data('deleting') == true
      exitDeleteMode()
    else
      enterDeleteMode()

enterDeleteMode = ->
  $deleteMode = $('#delete_mode')
  $deleteMode.find("span").text("Exit Delete Mode")
  $deleteMode.data('deleting', true)

  $deleteButton = $("""
    <a href="#" class="delete-button">
      Remove
    </a>
                    """)

  $deleteButton.click (e) ->
    $pad = $(e.currentTarget).closest(".pad")

    $pad.addClass "disabled"

    page = impamp.pads.getPage($pad)
    key  = impamp.pads.getKey($pad)

    impamp.storage.done (storage) ->
      storage.clearPad page, key, ->
        impamp.loadPad($pad)

        $(e.currentTarget).remove()
        return

  $('.pad').not(".disabled").append $deleteButton

exitDeleteMode = ->
  $deleteMode = $('#delete_mode')
  $deleteMode.find("span").text("Enter Delete Mode")
  $deleteMode.data('deleting', false)

  $('.pad').find(".delete-button").remove()
