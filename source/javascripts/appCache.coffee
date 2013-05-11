appCache = window.applicationCache

appCache.addEventListener 'downloading'
  , ->
    impamp.sync.enabled   = false
    impamp.setSyncButton "remove-sign", "Updating ImpAmp..."

    $('#syncBtn').unbind("click");
    $('#syncBtn').addClass("disabled")
  , false

appCache.addEventListener 'updateready'
  , ->
    appCache.swapCache()
    impamp.setSyncButton "remove-sign", "Updates Ready. Please refresh page to enable sync."
  , false