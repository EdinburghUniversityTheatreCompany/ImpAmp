$ ->
  $('.page-nav [href^="#page"]').click (e) ->
    return unless e.ctrlKey
    e.preventDefault()

    $pageNav = $(e.currentTarget)

    $modal = $(nameChangeModal)
    $('body').append($modal)
    $modal.modal('show')
    $modal.on 'hidden', ->
      $modal.remove()

    $('#renameInput').val($pageNav.data("name"))

    $('#renameButton').click (e) ->
      e.preventDefault()
      newName = $('#renameInput').val()

      impamp.storage.done (storage) ->
        storage.setPage impamp.pages.getPageNo($pageNav), newName, ->
          impamp.loadPage($pageNav)
          $modal.modal('hide')

      return false

    return false

nameChangeModal = """
<div class="modal hide fade">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
    <h3>Rename Page</h3>
  </div>
  <div class="modal-body">
    <input id="renameInput">
  </div>
  <div class="modal-footer">
    <a href="#" class="btn"  data-dismiss="modal"             >Cancel</a>
    <a href="#" class="btn btn-primary" id="renameButton">Rename</a>
  </div>
</div>
"""