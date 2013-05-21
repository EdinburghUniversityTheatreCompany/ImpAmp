$ ->
  $('.page-nav [href^="#page"]').click (e) ->
    return unless e.ctrlKey
    e.preventDefault()

    $pageNav = $(e.currentTarget)

    $modal = nameChangeModal()

    $('#renameInput').val($pageNav.data("name"))

    if $pageNav.attr("data-emergencies") == "1"
      $('#emergenciesInput').attr "checked", "checked"

    $modal.find('.modal-confirm').click (e) ->
      e.preventDefault()
      newName = $('#renameInput').val()

      emergencies = if $('#emergenciesInput').is(":checked") is true then 1 else 0

      impamp.storage.done (storage) ->
        storage.setPage impamp.pages.getPageNo($pageNav),
          name: newName
          emergencies: emergencies
        , ->
          impamp.loadPage($pageNav)
          $modal.modal('hide')

      return false

    return false

nameChangeModal = ->
  title = "Rename Page"
  body  = """
          <label>Page Name:</label>
          <input id="renameInput" type="text">
          <label class="checkbox">
            <input id="emergenciesInput" type="checkbox"> Contains Emergencies?
          </label>
          """

  return impamp.showModal(title, body, "Rename")