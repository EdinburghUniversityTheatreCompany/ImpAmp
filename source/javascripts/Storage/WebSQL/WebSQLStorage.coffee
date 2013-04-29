class window.WebSQLStorage
  @db: null;

  @convertDataURIToBlob: (dataURI) ->
    BASE64_MARKER = ";base64,"
    base64Index = dataURI.indexOf(BASE64_MARKER) + BASE64_MARKER.length
    base64 = dataURI.substring(base64Index)
    raw = window.atob(base64)
    rawLength = raw.length
    uInt8Array = new Uint8Array(rawLength)
    i = 0

    while i < rawLength
      uInt8Array[i] = raw.charCodeAt(i)
      ++i
    new Blob([uInt8Array.buffer])

  @rowToPad: (row) ->
    data =
      page: row.page
      key:  row.key
      name: row.name
      file: WebSQLStorage.convertDataURIToBlob row.file
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


  setPad: (page, key, name, file, callback) ->
    reader = new FileReader();
    reader.onload = (e) =>
      @db.transaction (tx) ->
        tx.executeSql """
                      INSERT OR REPLACE INTO Pads VALUES (?, ?, ?, ?)
                      """
        , [page, key, name, e.target.result],
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
    data.pads = {}

    @db.transaction (tx) ->
      tx.executeSql "SELECT * FROM Pads"
      , []
      , (tx, results) ->
        i = 0
        while i < results.rows.length
          row = results.rows.item(i)
          page = data.pads[row.page] || {}
          page[row.key] = row
          data.pads[row.page] = page
          i++

        json = JSON.stringify(data)
        blob = new Blob([json], { type: "application/json" })

        impamp.saveBlob("impamp.iajson", blob)
