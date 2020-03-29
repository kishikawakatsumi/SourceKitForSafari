window.jQuery = $ = require("jquery");
require("bootstrap");

const tippy = require("tippy.js");
const marked = require("marked");
const hljs = require("highlight.js");
marked.setOptions({
  highlight: function(code) {
    return hljs.highlight("swift", code).value;
  }
});

const GitUrlParse = require("git-url-parse");

const quickHelpElements = {};
const quickHelpTemplate = `
<div class="--sourcekit-for-safari　row">
  <div class="col-12">
    <div>
      <ul class="--sourcekit-for-safari nav nav-tabs p-2" role="tablist">
        <li class="nav-item tab-header-documentation"></li>
        <li class="nav-item tab-header-definition"></li>
      </ul>
    </div>
    <div class="tab-content"></div>
  </div>
</div>
`;

let codeNavigation = null;

function readLines(lines) {
  const contents = [];
  lines.forEach((line, index) => {
    contents.push(line.innerText.replace(/^[\r\n]+|[\r\n]+$/g, ""));
    readLine(line, index, 0);
  });
  return contents.join("\n");
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
      node.parentNode.insertBefore(element, node);
      node.parentNode.removeChild(node);

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

function setupQuickHelp(element, popoverContent) {
  $(element).popover({
    html: true,
    content: popoverContent,
    trigger: "manual",
    placement: "top",
    modifiers: [
      {
        name: "flip",
        options: {
          fallbackPlacements: ["bottom"]
        }
      }
    ]
  });
  $(element).on("click", event => {
    event.stopPropagation();
    $(".--sourcekit-for-safari_quickhelp")
      .not(element)
      .popover("hide");
    $(element).popover("toggle");
  });
  $(document).on("click", ".popover", event => {
    event.stopPropagation();
  });
  $(document).off("click", "html");
  $(document).on("click", "html", () => {
    hideAllQuickHelpPopovers();
  });
  $(element).on("shown.bs.popover", () => {
    document.querySelectorAll(".nav-link").forEach(nav => {
      nav.dataset.toggle = "tab";
    });
    document
      .querySelectorAll(".--sourcekit-for-safari_jump-to-definition")
      .forEach(link => {
        $(link).on("click", () => {
          hideAllQuickHelpPopovers();
        });
      });
  });
}

function setupQuickHelpContent(suffix) {
  return (() => {
    const id = `quickhelp${suffix}`;
    const quickHelp = quickHelpElements[id];
    const popover = quickHelp ? $(quickHelp) : $(quickHelpTemplate);
    popover.attr("id", id);
    quickHelpElements[id] = popover;
    return popover;
  })();
}

function hideAllQuickHelpPopovers() {
  $(".--sourcekit-for-safari_quickhelp").popover("hide");
}

function dispatchMessage(messageName, userInfo) {
  if (typeof safari !== "undefined") {
    safari.extension.dispatchMessage(messageName, userInfo);
  } else {
    chrome.runtime.sendMessage(
      { messageName: messageName, userInfo: userInfo },
      res => {
        const response = JSON.parse(res);
        if (response.result !== "success") {
          return;
        }
        const location = normalizedLocation();
        const parsedUrl = GitUrlParse(location);
        handleResponse(
          {
            name: "response",
            message: {
              request: response.request,
              value: response.value,
              line: userInfo.line,
              character: userInfo.character
            }
          },
          parsedUrl
        );
      }
    );
  }
}

function handleResponse(event, parsedUrl) {
  switch (event.name) {
    case "response":
      switch (event.message.request) {
        case "documentSymbol":
          (() => {
            if (codeNavigation) {
              codeNavigation.destroy();
              codeNavigation = null;
            }

            const value = event.message.value;
            if (value && Array.isArray(value)) {
              const symbols = value.filter(documentSymbol => {
                return isNaN(documentSymbol.kind);
              });
              if (!symbols.length) {
                return;
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
              navigationHeader.href =
                "#--sourcekit-for-safari_symbol-navigation-items";
              navigationHeader.classList.add(
                "list-group-item",
                "list-group-item-action"
              );
              navigationHeader.dataset.toggle = "collapse";
              navigationHeader.innerHTML = "Symbol Navigator ▾";
              navigationHeader.style.cssText = `font-family: ${style.fontFamily}; font-size: ${style.fontSize}; font-weight: bold;`;
              navigationList.appendChild(navigationHeader);

              const navigationItemContainer = document.createElement("div");
              navigationItemContainer.classList.add("collapse", "show");
              navigationItemContainer.id =
                "--sourcekit-for-safari_symbol-navigation-items";
              navigationList.appendChild(navigationItemContainer);

              symbols.forEach(documentSymbol => {
                if (!isNaN(documentSymbol.kind)) {
                  return;
                }

                const symbolLetter = documentSymbol.kind
                  .slice(0, 1)
                  .toUpperCase();
                const imageSource = (() => {
                  if (typeof safari !== "undefined") {
                    return `${safari.extension.baseURI}${symbolLetter}`;
                  } else {
                    return chrome.extension.getURL(`images/${symbolLetter}`);
                  }
                })();
                const supportedSymbols = ["S", "C", "I", "P", "M", "F", "E"];
                const indentationStyle = `style="margin-left: ${10 *
                  documentSymbol.indent}px;"`;
                const icon = supportedSymbols.includes(symbolLetter)
                  ? `<img srcset="${imageSource}.png, ${imageSource}@2x.png 2x, ${imageSource}@3x.png 3x" width="16" height="16" align="center" ${indentationStyle} />`
                  : symbolLetter;

                const navigationItem = document.createElement("a");
                navigationItem.classList.add(
                  "list-group-item",
                  "list-group-item-action",
                  "text-nowrap"
                );
                navigationItem.href = `${parsedUrl.href}#L${documentSymbol.start
                  .line + 1}`;
                navigationItem.innerHTML = `${icon} ${documentSymbol.name}`;
                navigationItem.style.cssText = "white-space: nowrap;";
                navigationItemContainer.appendChild(navigationItem);
              });

              codeNavigation = tippy(document.querySelector(".blob-wrapper"), {
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
              codeNavigation.show();
            }
          })();
          break;
        case "hover":
          (() => {
            const suffix = `-${event.message.line}-${event.message.character}`;
            document.querySelectorAll(`.symbol${suffix}`).forEach(element => {
              if (
                !element.dataset.hoverRequestState ||
                element.dataset.documentation
              ) {
                return;
              }

              const value = event.message.value;
              if (value) {
                const documentation = `${marked(value)}`;
                element.dataset.documentation = documentation;
                element.dataset.hoverRequestState = "finished";
                element.classList.add("--sourcekit-for-safari_quickhelp");

                const documentationContainer = document.createElement("div");
                documentationContainer.classList.add(
                  "--sourcekit-for-safari_documentation-container",
                  "--sourcekit-for-safari_documentation"
                );
                documentationContainer.innerHTML = documentation;

                const tabContent = document.createElement("div");
                tabContent.innerHTML = `
                  <div class="tab-pane active overflow-auto" id="documentation${suffix}" role="tabpanel" aria-labelledby="documentation-tab">
                    ${documentationContainer.outerHTML}
                  </div>
                `;

                const popoverContent = setupQuickHelpContent(suffix);
                $(".tab-header-documentation", popoverContent).replaceWith(
                  `
                  <li class="nav-item tab-header-documentation">
                    <a class="nav-link active" id="documentation-tab${suffix}" data-toggle="tab" href="#documentation${suffix}" role="tab" aria-controls="documentation" aria-selected="true">Documentation</a>
                  </li>
                  `
                );
                $(".nav-link", popoverContent).attr("data-toggle", "tab");
                $(".tab-content", popoverContent).append(tabContent.innerHTML);

                const popover = $(element).data("bs.popover");
                if (popover) {
                  popover.config.content = popoverContent.prop("outerHTML");
                } else {
                  setupQuickHelp(element, popoverContent);
                }
              }
            });
          })();
          break;
        case "definition":
          (() => {
            const suffix = `-${event.message.line}-${event.message.character}`;
            document.querySelectorAll(`.symbol${suffix}`).forEach(element => {
              if (
                !element.dataset.definitionRequestState ||
                element.dataset.definition
              ) {
                return;
              }

              const value = event.message.value;
              if (value && value.locations) {
                const definitions = [];
                value.locations.forEach(location => {
                  if (location.uri) {
                    const href = `${parsedUrl.protocol}://${parsedUrl.resource}/${parsedUrl.full_name}/${parsedUrl.filepathtype}/${parsedUrl.ref}/${location.uri}`;
                    definitions.push({
                      href: href,
                      path: location.uri,
                      content: location.content
                    });
                  } else {
                    definitions.push({
                      path: location.filename,
                      content: location.content
                    });
                  }
                });

                // prettier-ignore
                const definition = definitions
                  .map(definition => {
                    const href = definition.href || ""
                    const referenceLineNumber = href
                      .replace(parsedUrl.href, "")
                      .replace("#L", "");
                    const onThisFile = href.includes(parsedUrl.href);
                    const thisIsTheDefinition = onThisFile && referenceLineNumber == +element.dataset.lineNumber + 1;
                    const text = thisIsTheDefinition ? `<div class="--sourcekit-for-safari_text-bold">This is the definition</div>` : `Defined ${onThisFile ? "on" : "in"}`;
                    const linkOrText = href ?
                      `<a class="--sourcekit-for-safari_jump-to-definition --sourcekit-for-safari_text-bold" href="${href}">${thisIsTheDefinition ? "" : onThisFile ? `line ${referenceLineNumber}` : definition.path}</a>` :
                      `<span class="--sourcekit-for-safari_text-bold">${definition.path}</span>`
                    return `
                      <div class="--sourcekit-for-safari_bg-gray">
                        ${text} ${linkOrText}
                      </div>
                      <div>
                        <pre class="--sourcekit-for-safari_code"><code>${hljs.highlight("swift", definition.content).value}</code></pre>
                      </div>
                      `;
                  })
                  .join("\n");
                element.dataset.definition = definition;
                element.dataset.definitionRequestState = "finished";
                element.classList.add("--sourcekit-for-safari_quickhelp");

                const definitionContainer = document.createElement("div");
                definitionContainer.innerHTML = definition;

                const tabContent = document.createElement("div");
                tabContent.innerHTML = `
                  <div class="tab-pane overflow-auto" id="definition${suffix}" role="tabpanel" aria-labelledby="definition-tab">
                    ${definitionContainer.outerHTML}
                  </div>
                `;

                const popoverContent = setupQuickHelpContent(suffix);
                $(".tab-header-definition", popoverContent).replaceWith(
                  `
                  <li class="nav-item tab-header-definition">
                    <a class="nav-link" id="definition-tab${suffix}" data-toggle="tab" href="#definition${suffix}" role="tab" aria-controls="definition" aria-selected="true">Definition</a>
                  </li>
                  `
                );
                $(".nav-link", popoverContent).attr("data-toggle", "tab");
                $(".tab-content", popoverContent).append(tabContent.innerHTML);

                const popover = $(element).data("bs.popover");
                if (popover) {
                  popover.config.content = popoverContent.prop("outerHTML");
                } else {
                  setupQuickHelp(element, popoverContent);
                }
              }
            });
          })();
          break;
        default:
          break;
      }
      break;
    default:
      break;
  }
}

const activate = () => {
  const location = normalizedLocation();
  const parsedUrl = GitUrlParse(location);
  if (!parsedUrl) {
    return;
  }
  if (parsedUrl.resource !== "github.com") {
    return;
  }
  if (!parsedUrl.owner || !parsedUrl.name) {
    return;
  }
  dispatchMessage("initialize", {
    url: parsedUrl.toString("https"),
    resource: parsedUrl.resource,
    owner: parsedUrl.owner,
    name: parsedUrl.name,
    href: parsedUrl.href
  });

  if (parsedUrl.filepathtype !== "blob") {
    return;
  }

  const lines = document.querySelectorAll(".blob-code");
  const text = readLines(lines);

  dispatchMessage("didOpen", {
    resource: parsedUrl.resource,
    slug: parsedUrl.full_name,
    filepath: parsedUrl.filepath,
    text: text
  });

  const onMouseover = e => {
    let element = e.target;

    if (!element.classList.contains("symbol")) {
      return;
    }
    if (element.dataset.parentClassList.split(" ").includes("pl-c")) {
      return;
    }
    if (!element.dataset.hoverRequestState) {
      element.dataset.hoverRequestState = `requesting-${+element.dataset
        .lineNumber}:${+element.dataset.column}`;
      dispatchMessage("hover", {
        resource: parsedUrl.resource,
        slug: parsedUrl.full_name,
        filepath: parsedUrl.filepath,
        line: +element.dataset.lineNumber,
        character: +element.dataset.column,
        text: element.innerText
      });
    }
    if (!element.dataset.definitionRequestState) {
      element.dataset.definitionRequestState = `requesting-${+element.dataset
        .lineNumber}:${+element.dataset.column}`;
      dispatchMessage("definition", {
        resource: parsedUrl.resource,
        slug: parsedUrl.full_name,
        filepath: parsedUrl.filepath,
        line: +element.dataset.lineNumber,
        character: +element.dataset.column,
        text: element.innerText
      });
    }
  };
  document.addEventListener("mouseover", onMouseover);

  if (typeof safari !== "undefined") {
    safari.self.addEventListener("message", event => {
      handleResponse(event, parsedUrl);
    });
  }
};

function normalizedLocation() {
  return document.location.href.replace(/#.*$/, "");
}

let href = normalizedLocation();
window.onload = () => {
  let body = document.querySelector("body"),
    observer = new MutationObserver(mutations => {
      mutations.forEach(mutation => {
        const newLocation = normalizedLocation();
        if (href != newLocation) {
          href = newLocation;
          setTimeout(() => {
            activate();
          }, 1000);
        }
      });
    });

  const config = {
    childList: true,
    subtree: true
  };

  observer.observe(body, config);
};

if (typeof safari !== "undefined") {
  document.addEventListener("DOMContentLoaded", event => {
    require("./index.css");
    activate();
  });
} else {
  activate();
}
