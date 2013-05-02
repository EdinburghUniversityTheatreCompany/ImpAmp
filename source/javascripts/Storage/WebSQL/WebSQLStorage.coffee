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

    @db = openDatabase 'ImpAmpDB', '1.0', 'ImpAmp storage database', 2 * 1024 * 1024 * 1024
    @db.transaction (tx) ->
      tx.executeSql """
                    CREATE TABLE IF NOT EXISTS Pads(
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
      , [], ->
        impamp.storage.resolve me
      , (tx, error) ->
        console.log error

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


  setPad: (page, key, name, file, filename, filesize, callback, updatedAt = new Date()) ->
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

  removePad: (page, key, callback) ->
    @db.transaction (tx) ->
      tx.executeSql "DELETE FROM Pads WHERE page=? AND key=?"
        , [page, key]
        , (tx, results) ->
          callback?()

  export: ->
    data = {}
    data.pages = {}

    @db.transaction (tx) ->
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
        for key, row of page
          ((row, db) ->
            deferred = $.Deferred()
            transactions.push(deferred.promise())
            db.transaction (tx) ->
              tx.executeSql """
                            INSERT OR REPLACE INTO Pads VALUES (?, ?, ?, ?, ?, ?, ?)
                            """
              , [row.page, row.key, row.name, row.file, row.filename, row.filesize, row.updatedAt]
              , ->
                deferred.resolve()
              , (tx, error) ->
                console.log error
          )(row, @db)
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