impamp.saveBlob = (fileName, blob) ->
  downloadLink = document.createElement("a");
  downloadLink.href = window.webkitURL.createObjectURL(blob);
  downloadLink.download = fileName;
  downloadLink.click();
  downloadLink = null
  return