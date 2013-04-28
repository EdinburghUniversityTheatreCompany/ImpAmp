impamp.featureDetection.done (preferredStorage) ->
  return unless preferredStorage == impamp.storageTypes.WEB_SQL

  storage = new WebSQLStorage()