appCache = window.applicationCache

appCache.addEventListener 'downloading'
  , ->
    impamp.sync.enabled   = false
    impamp.setSyncButton "remove-sign", "Updating ImpAmp..."
  , false

# After first cache
appCache.addEventListener 'cached'
  , ->
    # We already have the correct versions, no need to reload.

    impamp.sync.enabled = true
    impamp.setSyncButton "time", "Waiting for Sync"

  , false

# After updates
appCache.addEventListener 'updateready'
  , ->
    # The browser will have loaded the old scripts. To ensure that we
    # don't break anything by syncing with old scripts, disable sync
    # until after reloading.

    $('#syncBtn').unbind("click");
    $('#syncBtn').addClass("disabled")

    appCache.swapCache()
    impamp.setSyncButton "remove-sign", "Updates Ready. Please refresh page to enable sync."
  , false