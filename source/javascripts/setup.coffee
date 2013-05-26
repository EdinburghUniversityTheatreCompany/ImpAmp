# Browser specifics
window.BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder ||
                     window.MozBlobBuilder || window.MSBlobBuilder;

# If localStorage isn't defined, make it look blank.
window.localStorage ||= {}

window.impamp = impamp = {};

impamp.storageTypes =
  INDEXED_DB: 1
  WEB_SQL:    2

# jQuery deferred objects:
impamp.docReady   = $.Deferred();
impamp.storage    = $.Deferred();
impamp.padsLoaded = $.Deferred();


$ ->
  impamp.docReady.resolve();

  $page1Nav = $('.page-nav [href="#page_1"]')
  $page1Nav.click()
