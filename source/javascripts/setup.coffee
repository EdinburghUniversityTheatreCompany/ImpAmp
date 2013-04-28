window.BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder ||
                     window.MozBlobBuilder || window.MSBlobBuilder;
window.impamp = impamp = {};

impamp.storageTypes =
  INDEXED_DB: 1
  WEB_SQL:    2

# jQuery deferred objects:
impamp.docReady = $.Deferred();
impamp.storage = $.Deferred();


$ ->
  impamp.docReady.resolve();