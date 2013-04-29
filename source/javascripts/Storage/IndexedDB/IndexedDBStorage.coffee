class window.IndexedDBStorage
  @db: null;

  constructor: ->
    @db = null

    version = 4;
    request = indexedDB.open "ImpAmpDB", version;
    request.onsuccess = (e) =>
      @db = e.target.result
      impamp.storage.resolve this
    request.onerror = (e) ->
      console.log e

    request.onupgradeneeded = (e) =>
      db = e.target.result;
      store = db.createObjectStore "pad",
        keyPath: ['page', 'key']
      store.createIndex("page, key", ['page', 'key'], { unique: true })

  getPad: (page, key, callback) ->
    trans = @db.transaction(["pad"], "readwrite")
    store = trans.objectStore("pad")
    index = store.index("page, key");
    index.get([page, key]).onsuccess = (e) ->
      callback e.target.result


  setPad: (page, key, name, file, callback) ->
    trans = @db.transaction(["pad"], "readwrite")
    store = trans.objectStore("pad")
    request = store.put(
      page: page
      key:  key
      name: name
      file: file
    )
    request.onsuccess = (e) ->
      callback?()

    request.onerror = (e) ->
      console.log e.value

  removePad: (page, key, callback) ->
    trans = @db.transaction(["pad"], "readwrite")
    store = trans.objectStore("pad")
    request = store.delete(page, key)
    request.onsuccess = ->
      callback?()

  export: ->
    #http://www.raymondcamden.com/index.cfm/2012/8/23/Proof-of-Concept--Build-a-download-feature-for-IndexedDB

    data = {}
    data.pages = {}

    trans = @db.transaction(["pad"], "readonly")
    store = trans.objectStore("pad")
    cursor = store.openCursor()
    cursor.onsuccess = (e) ->
      result = e.target.result
      if result
        pad = result.value
        pad.readable = true # Shouldn't be necessary, but FireFox isn't allowing access to properties unless you set something first...
        reader = new FileReader();
        reader.onload = (e) =>
          page = data.pages[pad.page] || {}

          page[pad.key] = pad
          pad.file = e.target.result

          data.pages[pad.page] = page
          result.continue();
        reader.readAsDataURL(pad.file);

    trans.oncomplete = ->
      json = JSON.stringify(data)
      blob = new Blob([json], { type: "application/json" })

      impamp.saveBlob("impamp.iajson", blob)

  import: (file, progress, callback) ->
    return