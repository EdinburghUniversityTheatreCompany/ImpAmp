window.BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder ||
                     window.MozBlobBuilder || window.MSBlobBuilder;
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
  $page1 = $($page1Nav.attr('href'))
  $page1Nav.click()
  impamp.addPageHandlers($page1)
