class window.IndexedDBStorage
  @db: null;

  constructor: ->
    @db = null

    version = 5;
    request = indexedDB.open "ImpAmpDB", version;
    request.onsuccess = (e) =>
      @db = e.target.result
      impamp.storage.resolve this
    request.onerror = (e) ->
      console.log e

    request.onupgradeneeded = (e) =>
      db = e.target.result;

      if e.oldVersion < 4
        store = db.createObjectStore "pad",
          keyPath: ['page', 'key']
        store.createIndex("page, key", ['page', 'key'], { unique: true })

      if e.oldVersion < 5
        store = db.createObjectStore "page",
          keyPath: "pageNo"
        store.createIndex("pageNo", ["pageNo"], { unique : true })

  getPad: (page, key, callback) ->
    trans = @db.transaction(["pad"], "readwrite")
    store = trans.objectStore("pad")
    index = store.index("page, key");
    index.get([page, key]).onsuccess = (e) ->
      callback e.target.result


  setPad: (page, key, name, file, filename, filesize, callback, updatedAt = new Date().getTime()) ->
    trans = @db.transaction(["pad"], "readwrite")
    store = trans.objectStore("pad")
    request = store.put(
      page: page
      key:  key
      name: name
      file: file
      filename:  filename
      filesize:  filesize
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

  setPage: (pageNo, name, callback, updatedAt = new Date().getTime()) ->
    trans = @db.transaction(["page"], "readwrite")
    store = trans.objectStore("page")
    request = store.put
      pageNo:    pageNo
      name:      name
      updatedAt: updatedAt

    request.onsuccess = (e) ->
      callback?()

    request.onerror = (e) ->
      console.log e.value

  getPage: (pageNo, callback) ->
    trans = @db.transaction(["page"], "readwrite")
    store = trans.objectStore("page")
    index = store.index("pageNo");
    index.get([pageNo]).onsuccess = (e) ->
      callback e.target.result

  export: ->
    #http://www.raymondcamden.com/index.cfm/2012/8/23/Proof-of-Concept--Build-a-download-feature-for-IndexedDB

    data = {}
    data.pages = {}

    promises = []

    trans = @db.transaction(["pad, page"], "readonly")

    pageStore = trans.objectStore("page")
    padStore  = trans.objectStore("pad")

    pageCursor = pageStore.openCursor()
    pageCursor.onsuccess = (e) ->
      result = e.target.result
      if result
        dbPage = result.value
        dbPage.readable = true # Shouldn't be necessary, but FireFox isn't allowing access to properties unless you set something first...

        page = data.pages[dbPage.pageNo] || {}

        page.name      = dbPage.name
        page.updatedAt = dbPage.updatedAt

        data.pages[dbPage.pageNo] = page

        result.continue();
        return

    padCursor = padStore.openCursor()
    padCursor.onsuccess = (e) ->
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
        me.setPage num, page.name, null, row.updatedAt
        for key, row of page
          ((row, me) ->
            deferred = $.Deferred()
            promises.push(deferred.promise())

            file = impamp.convertDataURIToBlob row.file

            me.setPad row.page, row.key, row.name, file, row.filename, row.filesize, ->
              deferred.resolve()
            , row.updatedAt
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