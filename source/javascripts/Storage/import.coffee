fs = impamp.filesystem

$ ->
  $("#importBtn").click ->
    $modal = $(importModal)
    $('body').append($modal)
    $modal.modal('show')
    $modal.on 'hidden', ->
      $modal.remove()

    $('#modalImportButton').click ->
      $file_input = $modal.find("input[type='file']")
      file = $file_input[0].files[0]

      $file_input.addClass("disabled")
      $file_input.attr("disabled", "disabled")
      $('#modalImportButton').click (e) ->
        e.preventDefault()
        return false

      impamp.storage.done (storage) ->
        storage.import file
        , (complete, total) ->
          $progress_bar = $modal.find(".progress .bar")
          $progress_bar.css
            width: ((complete/total) * 100) + "%"
          return
        , ->
          impamp.loadPads()
          $modal.modal('hide')
          return


importModal = """
<div class="modal hide fade">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
    <h3>Import Pads from File</h3>
  </div>
  <div class="modal-body">
    <input type="file" accept=".iajson">
    <div class="progress">
      <div class="bar"></div>
    </div>
  </div>
  <div class="modal-footer">
    <a href="#" class="btn"  data-dismiss="modal"             >Cancel</a>
    <a href="#" class="btn btn-primary" id="modalImportButton">Import</a>
  </div>
</div>
"""