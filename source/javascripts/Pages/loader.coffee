$.when(impamp.storage, impamp.docReady).done (storage) ->
  impamp.loadPages(storage)

impamp.loadPages = loadPages = (storage) ->
  $('.page-nav [href^="#page"]').each (i, pageNav) ->
    $pageNav = $(pageNav)

    loadPage($pageNav, storage)

impamp.loadPage  = loadPage  = ($pageNav, storage) ->
  if not storage?
    impamp.storage.done (storage) ->
      impamp.loadPage($pageNav, storage)
    return

  pageNo = impamp.pages.getPageNo $pageNav

  storage.getPage pageNo, (pageData) ->
    if not pageData?
      $pageNav.html "Page #{pageNo}"
      return

    $pageNav.html """
      Page #{pageData.pageNo}<br />
      #{pageData.name}
                  """