$ ->
  $('.page-nav [href^="#page"]').click (e) ->
    return unless e.ctrlKey
    e.preventDefault()

    $pageNav = $(e.currentTarget)

    $modal = nameChangeModal()

    $('#renameInput').val($pageNav.data("name"))
    $modal.find('.modal-confirm').click (e) ->
      e.preventDefault()
      newName = $('#renameInput').val()

      impamp.storage.done (storage) ->
        storage.setPage impamp.pages.getPageNo($pageNav), { name: newName }, ->
          impamp.loadPage($pageNav)
          $modal.modal('hide')

      return false

    return false

nameChangeModal = ->
  title = "Rename Page"
  body  = """
          <input id="renameInput">
          """

  return impamp.showModal(title, body, "Rename")