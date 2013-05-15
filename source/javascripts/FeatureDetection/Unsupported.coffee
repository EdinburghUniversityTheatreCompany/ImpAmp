impamp.featureDetection.fail ->
  impamp.docReady.done ->
    body =  """
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
            """

    title = "Unsupported Browser"

    impamp.showModal(title, body, "", false, "static", false)