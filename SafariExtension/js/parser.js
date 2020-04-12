let textDocument = null;

function readLines(lines) {
  textDocument = [];
  const contents = [];
  lines.forEach((line, index) => {
    textDocument.push(line);
    contents.push(line.innerText.replace(/^[\r\n]+|[\r\n]+$/g, ""));
  });
  readSlice(lines, 0);
  return contents.join("\n");
}

function readSlice(lines, sliceStart) {
  var nextSlice = sliceStart+100;
  for (var i=sliceStart ; i<nextSlice && i<lines.length; i++)
    readLine(lines[i], i, 0);
  if (nextSlice < lines.length)
    setTimeout(() => {
        readSlice(lines, nextSlice);
    }, 100);
}

function readLine(line, lineIndex, columnIndex) {
  let nodes = line.childNodes;
  for (var i = 0; i < nodes.length; i++) {
    const node = nodes[i];
    if (node.nodeName === "#text") {
      if (!node.nodeValue.trim()) {
        columnIndex += node.nodeValue.length;
        continue;
      }
      var element = document.createElement("span");
      element.classList.add("symbol", `symbol-${lineIndex}-${columnIndex}`);
      element.dataset.lineNumber = lineIndex;
      element.dataset.column = columnIndex;
      element.dataset.parentClassList = `${node.parentNode.classList}`;
      element.innerText = node.nodeValue;
      node.parentNode.replaceChild(element, node);

      columnIndex += node.nodeValue.length;
    } else {
      node.classList.add("symbol", `symbol-${lineIndex}-${columnIndex}`);
      node.dataset.lineNumber = lineIndex;
      node.dataset.column = columnIndex;
      if (node.childNodes.length > 0) {
        readLine(node, lineIndex, columnIndex);
        columnIndex += node.innerText.length;
      }
    }
  }
}

function highlightReferences(documentHighlights) {
  documentHighlights.forEach(documentHighlight => {
    const start = documentHighlight.start;
    const end = documentHighlight.end;
    if (start.line != end.line) {
      return;
    }
    const line = textDocument[start.line];
    let column = 0;
    line.childNodes.forEach(node => {
      let length = 0;
      if (node.nodeName === "#text") {
        length += node.nodeValue.length;
      } else {
        length += node.innerText.length;
      }
      if (column <= start.character && end.character < column + length) {
        node.classList.add("--sourcekit-for-safari_document-highlight");
        if (!node.matches(":hover")) {
          node.style.setProperty("background-color", "#8cc4ff");
        }
      }
      column += length;
    });
  });
}

exports.readLines = readLines;
exports.highlightReferences = highlightReferences;
