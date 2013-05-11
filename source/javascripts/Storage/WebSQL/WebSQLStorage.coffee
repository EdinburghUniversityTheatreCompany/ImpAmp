class window.WebSQLStorage
  @db: null;

  @rowToPad: (row) ->
    data =
      page: row.page
      key:  row.key
      name: row.name
      filename: row.filename
      filesize: row.filesize
      file: impamp.convertDataURIToBlob row.file
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
    rowToPad = @rowToPad
    @db.transaction (tx) ->
      tx.executeSql "SELECT * FROM Pads WHERE page=? AND key=?"
      , [page, key]
      , (tx, results) ->
        if results.rows.length <= 0
          callback null
        else
          row = results.rows.item(0)
          callback WebSQLStorage.rowToPad(row)


  setPad: (page, key, name, file, filename, filesize, callback, updatedAt = new Date().getTime()) ->
    reader = new FileReader();
    reader.onload = (e) =>
      @db.transaction (tx) ->
        tx.executeSql """
                      INSERT OR REPLACE INTO Pads VALUES (?, ?, ?, ?, ?, ?, ?)
                      """
        , [page, key, name, e.target.result, filename, filesize, updatedAt],
          callback?()
        , (tx, error) ->
          console.log error
    reader.readAsDataURL(file);

  setPadName: (page, key, name, callback, updatedAt = new Date().getTime()) ->
    @db.transaction (tx) ->
      tx.executeSql """
                    UPDATE Pads SET name = ?, updatedAt = ? WHERE page = ? AND key = ?
                    """
      , [name, updatedAt, page, key],
        callback?()
      , (tx, error) ->
        console.log error

  removePad: (page, key, callback) ->
    @db.transaction (tx) ->
      tx.executeSql "DELETE FROM Pads WHERE page=? AND key=?"
        , [page, key]
        , (tx, results) ->
          callback?()

  setPage: (pageNo, name, callback, updatedAt = new Date().getTime()) ->
    @db.transaction (tx) ->
      tx.executeSql """
                    INSERT OR REPLACE INTO Pages VALUES (?, ?, ?)
                    """
      , [pageNo, name, updatedAt],
        callback?()
      , (tx, error) ->
        console.log error

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