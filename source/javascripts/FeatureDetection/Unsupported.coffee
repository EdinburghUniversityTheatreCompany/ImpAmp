impamp.featureDetection.fail ->
  $modal = $(unsupportedModal)
  $('body').append($modal)
  $modal.modal('show')

unsupportedModal = """
<div class="modal hide fade" data-backdrop="static" data-keyboard="false">
  <div class="modal-header">
    <h3>Unsupported Browser</h3>
  </div>
  <div class="modal-body">
    <p>
      I'm sorry. It looks like your browser isn't able to run ImpAmp2.
    </p>
    <p>
      ImpAmp2 requires:
    </p>
    <ul>
      <li>HTML5 Audio Element support</li>
      <li>IndexedDB with Blob support or WebSQL</li>
    </ul>
  </div>
</div>
"""