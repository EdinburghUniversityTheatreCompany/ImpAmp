impamp.pages = {}

impamp.pages.getPageNo = ($pageNav) ->
  pageNo = $pageNav.attr('href').replace("#page_", "")

  return pageNo