# Storage Selection:
# Prefer indexeddb:
featureDetection = $.Deferred()
impamp.featureDetection = featureDetection.promise()

availableStorageTypes = []

resolvePreferred = ->
  if $.inArray(impamp.storageTypes.INDEXED_DB, availableStorageTypes) >= 0
    featureDetection.resolve impamp.storageTypes.INDEXED_DB
    return
  else if $.inArray(impamp.storageTypes.WEB_SQL, availableStorageTypes) >= 0
    featureDetection.resolve impamp.storageTypes.WEB_SQL
    return
  else
    featureDetection.reject()
    return

# See https://code.google.com/p/chromium/issues/attachmentText?id=108012&aid=1080120029000&name=blobtest.html&token=mK2xt15JSXDFPedj1Yk22t9erTg%3A1367167853893
testIDBBlobSupport = (callback) ->
  indexedDB = window.indexedDB or window.webkitIndexedDB
  dbname = "detect-blob-support"
  indexedDB.deleteDatabase(dbname).onsuccess = ->
    request = indexedDB.open(dbname, 1)
    request.onupgradeneeded = ->
      request.result.createObjectStore "store"

    request.onsuccess = ->
      db = request.result
      try
        db.transaction("store", "readwrite").objectStore("store").put new Blob(), "key"
        callback true
      catch e
        callback false
      finally
        db.close()
        indexedDB.deleteDatabase dbname

if not Modernizr.audio
  # It won't work. End of.
  featureDetection.reject()

if `Modernizr.audio.mp3 == false`
  $ ->
    $('#noMp3Warn').show();

if Modernizr.websqldatabase
  availableStorageTypes.push impamp.storageTypes.WEB_SQL

if Modernizr.indexeddb
  testIDBBlobSupport (supported) ->
    if supported == true
      availableStorageTypes.push impamp.storageTypes.INDEXED_DB
    resolvePreferred()
else
  resolvePreferred()
