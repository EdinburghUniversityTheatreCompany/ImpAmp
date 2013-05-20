impamp.saveBlob = (fileName, blob) ->
  downloadLink = document.createElement("a");
  downloadLink.href = window.URL.createObjectURL(blob);
  downloadLink.download = fileName;
  document.body.appendChild(downloadLink);
  downloadLink.click();
  document.body.removeChild(downloadLink);
  downloadLink = null
  return

impamp.convertDataURIToBlob = (dataURI) ->
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

#
# Compares newData and oldData to get the correct value.
# This allows "null" in newPadData to override an existing value
# in oldPadData
#
impamp.getValue = (property, newData, oldData) ->
  if property of newData
    return newData[property]
  else
    return (oldData || {})[property]

impamp.padColumns =
  [
    "page"
    "key"
    "name"
    "file"
    "filename"
    "filesize"
    "updatedAt"
  ]
impamp.pageColumns =
  [
    "pageNo"
    "name"
    "emergencies"
    "updatedAt"
  ]