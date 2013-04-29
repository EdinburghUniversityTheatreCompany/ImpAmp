impamp.featureDetection.done (preferredStorage) ->
  return unless preferredStorage == impamp.storageTypes.INDEXED_DB

  storage = new IndexedDBStorage()