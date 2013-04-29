$ ->
  $('#exportBtn').click ->
    impamp.storage.done (storage) ->
      storage.export()