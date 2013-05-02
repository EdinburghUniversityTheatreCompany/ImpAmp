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


  setPad: (page, key, name, file, filename, callback, updatedAt = new Date()) ->
    impamp.getBlobHash file, (filehash) =>
      trans = @db.transaction(["pad"], "readwrite")
      store = trans.objectStore("pad")
      request = store.put(
        page: page
        key:  key
        name: name
        file: file
        filename:  filename
        filehash:  filehash
        updatedAt: updatedAt
      )
      request.onsuccess = (e) ->
        callback?()

      request.onerror = (e) ->
        console.log e.value

  removePad: (page, key, callback) ->
    trans = @db.transaction(["pad"], "readwrite")
    store = trans.objectStore("pad")
    request = store.delete([page, key])
    request.onsuccess = ->
      callback?()

  export: ->
    #http://www.raymondcamden.com/index.cfm/2012/8/23/Proof-of-Concept--Build-a-download-feature-for-IndexedDB

    data = {}
    data.pages = {}

    promises = []

    trans = @db.transaction(["pad"], "readonly")
    store = trans.objectStore("pad")
    cursor = store.openCursor()
    cursor.onsuccess = (e) ->
      result = e.target.result
      if result
        pad = result.value
        pad.readable = true # Shouldn't be necessary, but FireFox isn't allowing access to properties unless you set something first...

        deferred = $.Deferred()
        promises.push(deferred.promise())

        reader = new FileReader();
        reader.onload = (e) ->
          page = data.pages[pad.page] || {}

          page[pad.key] = pad
          pad.file = e.target.result

          data.pages[pad.page] = page

          deferred.resolve()
          return
        reader.onerror = (e) ->
          deferred.reject()
          console.log e
          return
        reader.readAsDataURL(pad.file);

        result.continue();
        return

    trans.oncomplete = ->
      waiting = $.when.apply($, promises)
      waiting.then ->
        console.log "One done"
        return
      waiting.done ->
        json = JSON.stringify(data)
        blob = new Blob([json], { type: "application/json" })

        impamp.saveBlob("impamp.iajson", blob)

  import: (file, progress, callback) ->
    reader = new FileReader()
    reader.onload = (e) =>
      data = JSON.parse(e.target.result)

      promises = []
      for num, page of data.pages
        for key, row of page
          ((row, me) ->
            deferred = $.Deferred()
            promises.push(deferred.promise())

            file = impamp.convertDataURIToBlob row.file

            me.setPad row.page, row.key, row.name, file, row.filename, ->
              deferred.resolve()
          )(row, this)

      waiting  = $.when.apply($, promises)
      complete = 0
      waiting.then ->
        complete += 1
        progress?(complete, promises.length)
        return
      waiting.done ->
        callback?()
        return
    reader.readAsText(file);