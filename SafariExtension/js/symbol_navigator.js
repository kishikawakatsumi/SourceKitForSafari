const tippy = require("tippy.js");

let navigator = null;

function symbolNavigator(documentSymbols, documentUrl) {
  if (navigator) {
    navigator.destroy();
    navigator = null;
  }

  const navigationContainer = document.createElement("div");
  navigationContainer.classList.add(
    "--sourcekit-for-safari_symbol-navigation",
    "overflow-auto"
  );

  const navigationList = document.createElement("div");
  navigationList.classList.add("list-group", "col-12");

  const blobCodeInner = document.querySelector(".blob-code-inner");
  const style = getComputedStyle(blobCodeInner);
  navigationList.style.cssText = `font-family: ${style.fontFamily}; font-size: ${style.fontSize};`;

  navigationContainer.appendChild(navigationList);

  const navigationHeader = document.createElement("a");
  navigationHeader.href = "#--sourcekit-for-safari_symbol-navigation-items";
  navigationHeader.classList.add("list-group-item", "list-group-item-action");
  navigationHeader.dataset.toggle = "collapse";
  navigationHeader.innerHTML = "Symbol Navigator ▾";
  navigationHeader.style.cssText = `font-family: ${style.fontFamily}; font-size: ${style.fontSize}; font-weight: bold;`;
  navigationList.appendChild(navigationHeader);

  const navigationItemContainer = document.createElement("div");
  navigationItemContainer.classList.add("collapse", "show");
  navigationItemContainer.id = "--sourcekit-for-safari_symbol-navigation-items";
  navigationList.appendChild(navigationItemContainer);

  documentSymbols.forEach(documentSymbol => {
    if (!isNaN(documentSymbol.kind)) {
      return;
    }

    const symbolLetter = documentSymbol.kind.slice(0, 1).toUpperCase();
    const imageSource = (() => {
      if (typeof safari !== "undefined") {
        return `${safari.extension.baseURI}${symbolLetter}`;
      } else {
        return chrome.extension.getURL(`images/${symbolLetter}`);
      }
    })();
    const predefinedSymbols = ["S", "C", "I", "P", "M", "F", "E"];
    const indentationStyle = `style="margin-left: ${10 *
      documentSymbol.indent}px;"`;
    const icon = predefinedSymbols.includes(symbolLetter)
      ? `<img srcset="${imageSource}.png, ${imageSource}@2x.png 2x, ${imageSource}@3x.png 3x" width="16" height="16" align="center" ${indentationStyle} />`
      : symbolLetter;

    const navigationItem = document.createElement("a");
    navigationItem.classList.add(
      "list-group-item",
      "list-group-item-action",
      "text-nowrap"
    );
    navigationItem.href = `${documentUrl}#L${documentSymbol.start.line + 1}`;
    navigationItem.innerHTML = `${icon} ${documentSymbol.name}`;
    navigationItem.style.cssText = "white-space: nowrap;";
    navigationItemContainer.appendChild(navigationItem);
  });

  navigator = tippy(document.querySelector(".blob-wrapper"), {
    content: navigationContainer,
    interactive: true,
    arrow: false,
    animation: false,
    duration: 0,
    placement: "right-start",
    offset: [0, -100],
    theme: "light-border",
    trigger: "manual",
    hideOnClick: false
  });
  return navigator;
}

exports.symbolNavigator = symbolNavigator;
