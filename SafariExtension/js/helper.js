function normalizedLocation() {
  return document.location.href.replace(/#.*$/, "");
}

exports.normalizedLocation = normalizedLocation;
