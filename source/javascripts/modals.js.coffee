impamp.showModal = (title, body, confirmText = "Confirm", actions = true, backdrop = true, keyboard = true) ->
  $modal = $ """
              <div class="modal hide fade" data-backdrop="#{backdrop}" data-keyboard="#{keyboard}">
                <div class="modal-header">
                  <h3>#{title}</h3>
                </div>
                <div class="modal-body">
                  #{body}
                </div>
              </div>
            """

  if actions == true
    $modal.append(
                  """
                  <div class="modal-footer">
                    <a href="#" class="btn" data-dismiss="modal"     >Cancel</a>
                    <a href="#" class="btn btn-primary modal-confirm" >#{confirmText}</a>
                  </div>
                  """
                )

  $('body').append $modal

  $modal.on 'show', ->
    impamp.removeNavHandlers()
    impamp.removePadishKeyHandlers()

  $modal.on 'hidden', ->
    $modal.remove()
    impamp.addNavHandlers()
    $activePage = $('.pad-page.active')
    impamp.addPageHandlers($activePage)

  $modal.modal("show")

  return $modal