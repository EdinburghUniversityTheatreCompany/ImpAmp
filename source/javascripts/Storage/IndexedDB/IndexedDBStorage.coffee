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
      firstPad = true

      padCursor = padStore.getAll()
      padCursor.onerror = (e) -> throw e
      padCursor.onsuccess = (e) ->
        allValues = e.target.result

        fileStream = streamSaver.createWriteStream('impamp.iajson', {})
        writer = fileStream.getWriter()
        encode = TextEncoder.prototype.encode.bind(new TextEncoder)
        writer.write(encode("{ \"padCount\": #{JSON.stringify(allValues.length)}, \"pages\": {"))

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
    # oboe file reading based on https://gist.github.com/Aigeec/b202ae4866a9a6bd538dde57f5c30328
    oboeStream = oboe({disableBufferCheck: true})
    promises = []
    complete = 0
    padCount = 340

    readSingleFile = (file) ->
      if !file
        return
      start = 0
      stop = 524288 #1024*512
      reader = new FileReader

      reader.onloadend = (evt) ->
        if evt.target.readyState == FileReader.DONE
          oboeStream.emit 'data', evt.target.result
          if !stop
            return
          start = stop
          stop += 524288 #1024*512
          if stop > file.size
            # read to end of file
            stop = undefined
          readSlice reader, file, start, stop
        return

      readSlice reader, file, start, stop
      return

    readSlice = (reader, file, start, stop) ->
      blob = file.slice(start, stop)
      reader.readAsBinaryString blob
      return

    self = this
    oboeStream.node 'padCount', (node) -> padCount = node

    oboeStream.node 'pages.*.pads.*', (node) ->
      ((row, me) ->
        promises.push( new Promise( (resolve,reject) ->
          file = impamp.convertDataURIToBlob row.file

          self.setPad row.page, row.key,
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
          progress?(complete, padCount)
          return
        ))
      )(node, this)
      return oboeStream.drop

    oboeStream.on 'done', (data) ->
      for num, page of data.pages
        self.setPage num,
          name:        page.name
          emergencies: page.emergencies
        , null, page.updatedAt

      Promise.all(promises).then( ->
        progress?(complete, complete)
        callback?()
        return
      )

    readSingleFile(file)
