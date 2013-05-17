class window.WebSQLStorage
  @db: null;
  @padColumns:  [
                "page"
                "key"
                "name"
                "file"
                "filename"
                "filesize"
                "updatedAt"
                ]
  @pageColumns: [
                "pageNo"
                "name"
                "updatedAt"
                ]

  @rowToPad: (row) ->
    data =
      page: row.page
      key:  row.key
      name: row.name
      file: impamp.convertDataURIToBlob row.file
      filename: row.filename
      filesize: row.filesize
      updatedAt: row.updatedAt
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
      if not column in WebSQLStorage.padColumns
        console.warn "#{column} is not supported in WebSQLStorage."
        delete padData[column]

    updateDB = =>
      #
      # Compares newPadData and oldPadData to get the correct value.
      # This allows "null" in newPadData to override an existing value
      # in oldPadData
      #
      getValue = (property, newPadData, oldPadData) ->
        if property of newPadData
          return newPadData[property]
        else
          return (oldPadData || {})[property]

      @getPadRow page, key, (oldPadData) =>
        for column in WebSQLStorage.padColumns
          padData[column] = getValue(column, padData, oldPadData)

        padData.page ||= page
        padData.key  ||= key

        # Mostly for moving. If padData.key != key, then delete the old row
        # so that it acts like IndexedDB
        if (padData.page != page) || (padData.key != key)
          @removePad(page, key)

        @db.transaction (tx) ->
          tx.executeSql """
                        INSERT OR REPLACE INTO Pads VALUES (?, ?, ?, ?, ?, ?, ?)
                        """
          , [padData.page, padData.key, padData.name, padData.file, padData.filename, padData.filesize, updatedAt],
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

  removePad: (page, key, callback) ->
    @db.transaction (tx) ->
      tx.executeSql "DELETE FROM Pads WHERE page=? AND key=?"
        , [page, key]
        , (tx, results) ->
          callback?()

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
      if not column in WebSQLStorage.pageColumns
        console.warn "#{column} is not supported in WebSQLStorage."
        delete pageData[column]

    #
    # Compares newPageData and oldPageData to get the correct value.
    # This allows "null" in newPageData to override an existing value
    # in oldPageData
    #
    getValue = (property, newPageData, oldPageData) ->
      if property of newPageData
        return newPageData[property]
      else
        return (oldPageData || {})[property]

    @getPage page, key, (oldPageData) =>
      for column in WebSQLStorage.pageColumns
        pageData[column] = getValue(column, pageData, oldPageData)

      pageData.pageNo ||= pageNo

      @db.transaction (tx) ->
        tx.executeSql """
                    INSERT OR REPLACE INTO Pages VALUES (?, ?, ?)
                    """
        , [pageData.pageNo, pageData.name, updatedAt],
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
          page.name = row.name
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

      transactions = []
      for num, page of data.pages
        @db.transaction (tx) ->
          deferred = $.Deferred()
          transactions.push(deferred.promise())

          tx.executeSql """
                        INSERT OR REPLACE INTO Pages VALUES (?, ?, ?)
                        """
            , [num, page.name, page.updatedAt]
            , ->
              for key, row of page
                tx.executeSql """
                              INSERT OR REPLACE INTO Pads VALUES (?, ?, ?, ?, ?, ?, ?)
                              """
                , [row.page, row.key, row.name, row.file, row.filename, row.filesize, row.updatedAt]
                , ->
                  deferred.resolve()
                , (tx, error) ->
                  console.log error
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