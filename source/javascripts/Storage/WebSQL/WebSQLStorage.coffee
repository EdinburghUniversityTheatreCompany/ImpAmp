class window.WebSQLStorage
  @db: null

  @rowToPad: (row) ->
    if row.file?
      file = impamp.convertDataURIToBlob row.file

    data =
      page: row.page
      key:  row.key
      name: row.name
      file: file
      filename: row.filename
      filesize: row.filesize
      updatedAt: row.updatedAt
      startTime: row.startTime
      endTime:   row.endTime
    return data

  constructor: ->
    me = this;

    @db = openDatabase 'ImpAmpDB', '', 'ImpAmp storage database', 2 * 1024 * 1024 * 1024

    migrator = new WebSQLMigrator(@db)
    migrator.migration "", "1.0", (tx) ->
      tx.executeSql """
                    CREATE TABLE Pads(
                      page,
                      key,
                      name,
                      file,
                      filename,
                      filesize,
                      updatedAt,
                      PRIMARY KEY (page, key)
                    )
                    """

    migrator.migration "1.0", "1.1", (tx) ->
      tx.executeSql """
                    CREATE TABLE Pages(
                      pageNo,
                      name,
                      updatedAt,
                      PRIMARY KEY (pageNo)
                    )
                    """

    migrator.migration "1.1", "1.2", (tx) ->
      tx.executeSql """
                    ALTER TABLE Pages ADD emergencies
                    """

    migrator.migration "1.2", "1.3", (tx) ->
      tx.executeSql """
                    ALTER TABLE Pads ADD startTime
                    """
      tx.executeSql """
                    ALTER TABLE Pads ADD endTime
                    """

    migrator.migrate ->
      impamp.storage.resolve me

  getPad: (page, key, callback) ->
    @getPadRow page, key, (row) ->
      if row?
        callback WebSQLStorage.rowToPad(row)
      else
        callback null

  getPadRow: (page, key, callback) ->
    @db.transaction (tx) ->
      tx.executeSql "SELECT * FROM Pads WHERE page=? AND key=?"
      , [page, key]
      , (tx, results) ->
        if results.rows.length <= 0
          callback null
        else
          row = results.rows.item(0)
          callback row

  #
  # Create or update a pad
  # @param page      The current page of the pad to update, or page to create a pad on
  # @param key       The current key of the pad to update, or key to create a pad on
  # @param padData   The new data to use. When updating, existing values will be used if
  #                  they are not specified.
  # @param callback  A function with no arguments to call when the pad has been set.
  # @param updatedAt Note that this parameter (which defaults to the current time) will
  #                  override any updatedAt passed in padData.
  setPad: (page, key, padData, callback, updatedAt = new Date().getTime()) ->
    for column, value of padData
      if not column in impamp.padColumns
        delete padData[column]

    updateDB = =>
      @getPadRow page, key, (oldPadData) =>
        for column in impamp.padColumns
          padData[column] = impamp.getValue(column, padData, oldPadData)
          padData[column] ||= null

        padData.page ||= page
        padData.key  ||= key

        # Mostly for moving. If padData.key != key, then delete the old row
        # so that it acts like IndexedDB
        if (padData.page != page) || (padData.key != key)
          @clearPad(page, key)

        @db.transaction (tx) ->
          tx.executeSql """
                        INSERT OR REPLACE INTO Pads VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """
          , [padData.page, padData.key, padData.name, padData.file, padData.filename, padData.filesize, updatedAt, padData.startTime, padData.endTime],
            callback?()
          , (tx, error) ->
            throw error

    if padData.file
      file = padData.file

      reader = new FileReader();
      reader.onload = (e) =>
        padData.file = e.target.result
        updateDB()

      reader.readAsDataURL(file);
    else
      updateDB()

  clearPad: (page, key, callback) ->
    @setPad page, key
    ,
      name: null
      file: null
      filename: null
      filesize: null
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
    for column, value of pageData
      if not column in impamp.pageColumns
        delete pageData[column]

    #
    # Compares newPageData and oldPageData to get the correct value.
    # This allows "null" in newPageData to override an existing value
    # in oldPageData
    #
    @getPage pageNo, (oldPageData) =>
      for column in impamp.pageColumns
        pageData[column] = impamp.getValue(column, pageData, oldPageData)

      pageData.pageNo ||= pageNo

      @db.transaction (tx) ->
        tx.executeSql """
                    INSERT OR REPLACE INTO Pages VALUES (?, ?, ?, ?)
                    """
        , [pageData.pageNo, pageData.name, updatedAt, pageData.emergencies],
          callback?()
        , (tx, error) ->
            throw error

  getPage: (pageNo, callback) ->
    @db.transaction (tx) ->
      tx.executeSql "SELECT * FROM Pages WHERE pageNo=?"
      , [pageNo]
      , (tx, results) ->
        if results.rows.length <= 0
          callback null
        else
          row = results.rows.item(0)
          callback row

  export: ->
    data = {}
    data.pages = {}

    @db.transaction (tx) ->
      # Save page details:
      tx.executeSql "SELECT * FROM Pages"
      , []
      , (tx, dbPages) ->
        i = 0
        while i < dbPages.rows.length
          row = dbPages.rows.item(i)
          page = data.pages[row.pageNo] || {}
          page.name        = row.name
          page.emergencies = row.emergencies
          page.updatedAt   = row.updatedAt
          data.pages[row.pageNo] = page
          i++

        # Save pad details:
        tx.executeSql "SELECT * FROM Pads"
        , []
        , (tx, results) ->
          i = 0
          while i < results.rows.length
            row = results.rows.item(i)
            page = data.pages[row.page] || {}
            page[row.key] = row
            data.pages[row.page] = page
            i++

          json = JSON.stringify(data)
          blob = new Blob([json], { type: "application/json" })

          impamp.saveBlob("impamp.iajson", blob)

  import: (file, progress, callback) ->
    reader = new FileReader()
    reader.onload = (e) =>
      data = JSON.parse(e.target.result)

      pageTransactions = []
      transactions = []

      for num, page of data.pages
        pageDeferred = $.Deferred()
        pageTransactions.push(pageDeferred.promise())

        ((page, num, pageDeferred) =>
          @db.transaction (tx) ->
            tx.executeSql """
                          INSERT OR REPLACE INTO Pages VALUES (?, ?, ?, ?)
                          """
              , [num, page.name, page.updatedAt, page.emergencies]
              , ->
                pageDeferred.resolve()
                for key, row of page
                  deferred = $.Deferred()
                  transactions.push(deferred.promise())

                  tx.executeSql """
                                INSERT OR REPLACE INTO Pads VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                                """
                  , [row.page, row.key, row.name, row.file, row.filename, row.filesize, row.updatedAt, row.startTime, row.endTime]
                  , ->
                    deferred.resolve()
                  , (tx, error) ->
                    throw error
        )(page, num, pageDeferred)

      pageWait = $.when.apply(null, pageTransactions)
      pageWait.done ->
        waiting  = $.when.apply(null, transactions)
        complete = 0
        waiting.then ->
          complete += 1
          progress?(complete, transactions.length)
          return
        waiting.done ->
          callback?()
          return

    reader.readAsText(file);