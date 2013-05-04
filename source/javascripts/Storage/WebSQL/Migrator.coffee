# Based on http://blog.maxaller.name/2010/03/html5-web-sql-database-intro-to-versioning-and-migrations/

class window.WebSQLMigrator
  constructor: (db) ->
    @db = db
    @migrations = []

  # Despite newVersion not being used currently, it's more readable.
  migration: (oldVersion, newVersion, tx) ->
    @migrations[oldVersion] =
      newVersion:   newVersion
      transaction: tx

  doMigration: (oldVersion, callback) ->
    migration = @migrations[oldVersion]
    if migration?
      @db.changeVersion @db.version, migration.newVersion,
      (t) ->
        migration.transaction t
      , (err) ->
        console.error "Error!: %o", err  if console.error
      , =>
        doMigration @db.version, callback
    else
      # No further migrations. Callback.
      callback?()

  migrate: (callback) ->
    @doMigration @db.version, callback