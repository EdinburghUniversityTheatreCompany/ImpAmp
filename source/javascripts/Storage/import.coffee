fs = impamp.filesystem

$ ->
  $("#importBtn").click ->
    alert("This will overwrite blank pads or ones that are older than the data from this save file. Make sure you are synced with the server as if not you risk overwriting pads once you do sync with the server")
    $modal = importModal()

    $modal.find('.modal-confirm').click ->
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
          impamp.loadPages()
          impamp.loadPads()
          $modal.modal('hide')
          return


importModal = ->
  title = "Import Pads from File"
  body  = """
          <input type="file" accept=".iajson">
          <div class="progress">
            <div class="bar"></div>
          </div>
          """

  return impamp.showModal(title, body, "Import")