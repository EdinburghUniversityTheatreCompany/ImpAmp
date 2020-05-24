class window.IndexedDBStorage
  @db: null;
  streamSaver = window.streamSaver

  constructor: ->
    @db = null

    version = 5;
    request = indexedDB.open "ImpAmpDB", version;
    request.onsuccess = (e) =>
      @db = e.target.result
      impamp.storage.resolve this
    request.onerror = (e) ->
      throw e

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


  #
  # Create or update a pad
  # @param page      The current page of the pad to update, or page to create a pad on
  # @param key       The current key of the pad to update, or key to create a pad on
  # @param padData   The new data to use. When updating, existing values will be used if
  #                  they are not specified.
  # @param callback  A function with no arguments to call when the pad has been set.
  # @param updatedAt Note that this parameter (which defaults to the current time) will
  #                  override any updatedAt passed in padData.
  setPad: (page, key, padData, callback, updatedAt = new Date().getTime(), fromRestore= false) ->
    @getPad page, key, (oldPadData) =>
      if oldPadData && not oldPadData.file && fromRestore
        updatedAt = new Date().getTime()
      for column in impamp.padColumns
        padData[column] = impamp.getValue(column, padData, oldPadData)

      padData.updatedAt = updatedAt
      padData.page ||= page
      padData.key  ||= key

      if (padData.page != page) || (padData.key != key)
        @clearPad(page, key)

      trans = @db.transaction(["pad"], "readwrite")
      store = trans.objectStore("pad")

      request = store.put(padData)
      request.onsuccess = (e) ->
        callback?()

      request.onerror = (e) ->
        throw e

  clearPad: (page, key, callback) ->
    @setPad page, key
    ,
      name: null
      file: null
      filename: null
      filesize: null
      startTime: null
      endTime:   null
    , callback

  #
  # Create or update a page in the database.
  # @param pageNo    The number of the page
  # @param pageData  The new data to use. When updating, existing values will be used if
  #                  they are not specified.
  # @param callback  A function with no arguments to call when the pad has been set.
  # @param updatedAt Note that this parameter (which defaults to the current time) will
  #                  override any updatedAt passed in padData.
  setPage: (pageNo, pageData, callback, updatedAt = new Date().getTime()) ->
    @getPage pageNo, (oldPageData) =>
      trans = @db.transaction(["page"], "readwrite")
      store = trans.objectStore("page")

      filteredPageData = Object.keys(pageData)
        .filter((key) -> impamp.pageColumns.includes(key))
        .reduce((obj, key) ->
            obj[key] = pageData[key];
            return obj;
          , {});
      filteredPageData.updatedAt = updatedAt
      filteredPageData.pageNo ||= pageNo

      for column in impamp.pageColumns
        filteredPageData[column] = impamp.getValue(column, filteredPageData, oldPageData)

      request = store.put(filteredPageData)
      request.onsuccess = (e) ->
        callback?()

      request.onerror = (e) ->
        throw e

  getPage: (pageNo, callback) ->
    trans = @db.transaction(["page"], "readwrite")
    store = trans.objectStore("page")
    index = store.index("pageNo");
    index.get([pageNo]).onsuccess = (e) ->
      callback e.target.result

  export: ->
    #http://www.raymondcamden.com/index.cfm/2012/8/23/Proof-of-Concept--Build-a-download-feature-for-IndexedDB
    if !streamSaver.supported
      return alert("Sorry your browser doesnt support WritableStreams yet try updating yours (chrome should work)")

    data = {}
    data.pages = {}

    promises = []

    trans = @db.transaction(["pad", "page"], "readonly")

    pageStore = trans.objectStore("page")
    padStore  = trans.objectStore("pad")
    pages = {}

    pagePromise = new Promise (resolve,reject) ->
      pageStore.getAll().onsuccess = (event) ->
        pages = event.target.result
        resolve()

    pagePromise.then (e) ->
      lastPageNo = null
      fileStream = streamSaver.createWriteStream('impamp.iajson', {})
      writer = fileStream.getWriter()
      encode = TextEncoder.prototype.encode.bind(new TextEncoder)
      writer.write(encode("{ \"pages\": {"))
      firstPad = true

      padCursor = padStore.getAll()
      padCursor.onerror = (e) -> throw e
      padCursor.onsuccess = (e) ->
        allValues = e.target.result
        promise = Promise.resolve({index: 0, lock: Promise.resolve(0)})
        for _ in allValues
          promise = promise.then (e) ->
            new Promise( (resolve,reject) ->
              e.lock.then( (i) ->
                cursor = allValues[i]
                if cursor.page
                  if cursor.page != lastPageNo
                    firstPad = true
                    # write page meta data and start of container
                    if lastPageNo != null
                      writer.write(encode("}}, "))
                    writer.write(encode("\"#{cursor.page}\": {"))
                    first = true
                    for key in impamp.pageColumns
                      if !first
                        writer.write(encode(", "))
                      writer.write(encode("\"#{key}\": #{JSON.stringify(pages[cursor.page][key])}"))
                      first= false
                    writer.write(encode(', "pads": {'))
                    lastPageNo = cursor.page
                  if cursor.filename
                    if firstPad
                      firstPad = false
                    else
                      writer.write(encode(", "))

                    pad = cursor
                    pad.readable = true # Shouldn't be necessary, but FireFox isn't allowing access to properties unless you set something first...

                    filePromise = new Promise( (resolve2,reject2) ->
                      reader = new FileReader();
                      reader.onload = (e) ->
                        pad.file = e.target.result

                        writer.write(encode("#{JSON.stringify(cursor.key)}: #{JSON.stringify(pad)}"))
                        resolve2(i+1)
                      reader.onerror = (e) ->
                        throw e
                        reject2()
                      reader.readAsDataURL(pad.file);
                    )
                    resolve( {index: i+1, lock: filePromise})
                  else
                    resolve( {index: i+1, lock: Promise.resolve(i+1)})
                else
                  resolve( {index: i+1, lock: Promise.resolve(i+1)})
              )
            )
        promise.then( (e) ->
          # close: pads, page, pages, object
          e.lock.then ->
            writer.write(encode("}}}}"))
            writer.close()
        )

  import: (file, progress, callback) ->
    reader = new FileReader()
    reader.onload = (e) =>
      data = JSON.parse(e.target.result)

      promises = []
      complete = 0
      for num, page of data.pages
        @setPage num,
          name:        page.name
          emergencies: page.emergencies
        , null, page.updatedAt
        for key, row of page.pads
          ((row, me) ->
            promises.push( new Promise( (resolve,reject) ->
              file = impamp.convertDataURIToBlob row.file

              me.setPad row.page, row.key,
                name: row.name
                file: file
                filename: row.filename
                filesize: row.filesize
                startTime: row.startTime
                endTime:   row.endTime
              , ->
                resolve()
              , row.updatedAt
              , true
            ).then( ->
              complete += 1
              progress?(complete, promises.length)
              return
            ))
          )(row, this)

      Promise.all(promises).then( ->
        callback?()
        return
      )
    reader.readAsText(file);
