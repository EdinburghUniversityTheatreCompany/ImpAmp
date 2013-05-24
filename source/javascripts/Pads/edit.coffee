wavesurfer = null

impamp.editPad = ($pad) ->
  $modal = editPadModal()

  audioElement = $pad.find("audio")[0]

  $('#renameInput').val($pad.data("name"))

  $modal.on "shown", ->
    wsOptions =
      canvas: $('#wavesurfer')[0]
      waveColor: 'violet'
      progressColor: 'purple'

    if not wavesurfer?
      wavesurfer = Object.create(WaveSurfer)
      wavesurfer.init wsOptions
    else
      # Most of it's still valid. Just update the drawer and rebind click.
      wavesurfer.drawer.init wsOptions
      wavesurfer.bindClick wsOptions.canvas, (percents) ->
        wavesurfer.seekTo(percents)

    wavesurfer.load(audioElement.src)

    startTime = $pad.data("startTime")
    endTime   = $pad.data("endTime")

  $modal.on "hidden", ->
    wavesurfer.pause()

  $modal.find(".btn").on "click", editClickHandler

  $modal.find('.modal-confirm').click (e) ->
    e.preventDefault()

    newName   = $('#renameInput').val()
    startTime = (wavesurfer.drawer.markers["start"] || {position: null}).position
    endTime   = (wavesurfer.drawer.markers["end"]   || {position: null}).position

    page = impamp.pads.getPage $pad
    key  = impamp.pads.getKey  $pad

    impamp.storage.done (storage) ->
      storage.setPad page, key,
        name: newName
        startTime: startTime
        endTime:   endTime
      , ->
        impamp.loadPad($pad)
        $modal.modal('hide')

    return false

editClickHandler = (e) ->
  $button = $(e.currentTarget)
  action = $button.data("action")

  return unless action
  e.preventDefault()

  switch action
    when "play"
      wavesurfer.playPause();

    when "start-mark"
      wavesurfer.mark
        id: 'start'
        color: 'rgba(0, 255, 0, 0.5)'

    when "end-mark"
      wavesurfer.mark
        id: 'end'
        color: 'rgba(255, 0, 0, 0.5)'

    when "back"
      wavesurfer.skipBackward()

    when "forth"
      wavesurfer.skipForward()

editPadModal = ->
  title = "Edit Pad"
  body  = """
          <label>Name:</label>
          <input id="renameInput" type="text">

          <div>
            <canvas id="wavesurfer" style="width: 100%; height: 100px"></canvas>
          </div>

          <div class="btn-group">
              <button class="btn" data-action="back">
                <i class="icon icon-step-backward"></i>
              </button>

              <button class="btn" data-action="play">
                <i class="icon icon-play"></i>
              </button>

              <button class="btn" data-action="forth">
                <i class="icon icon-step-forward"></i>
              </button>

              <button class="btn btn-success" data-action="start-mark">
                <i class="icon icon-flag"></i>
                Start
              </button>

              <button class="btn btn-danger" data-action="end-mark">
                <i class="icon icon-flag"></i>
                End
              </button>
            </div>
          """

  return impamp.showModal(title, body, "Save")