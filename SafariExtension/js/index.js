window.jQuery = $ = require("jquery");
require("bootstrap");

const marked = require("marked");
const GitUrlParse = require("git-url-parse");

const hljs = require("highlight.js");
marked.setOptions({
  highlight: function(code) {
    return hljs.highlight("swift", code).value;
  }
});

const { readLines, highlightReferences } = require("./parser");
const { setupQuickHelp, setupQuickHelpContent } = require("./quickhelp");
const { symbolNavigator } = require("./symbol_navigator");
const { normalizedLocation } = require("./helper");

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
              character: userInfo.character,
              text: userInfo.text
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
            const value = event.message.value;
            if (value && Array.isArray(value)) {
              const symbols = value.filter(documentSymbol => {
                return isNaN(documentSymbol.kind);
              });
              if (!symbols.length) {
                return;
              }

              symbolNavigator(symbols, parsedUrl.href).show();
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
        case "references":
          break;
        case "documentHighlight":
          (() => {
            const suffix = `-${event.message.line}-${event.message.character}`;
            document.querySelectorAll(`.symbol${suffix}`).forEach(element => {
              if (
                !element.dataset.documentHighlightRequestState ||
                element.dataset.documentHighlight
              ) {
                return;
              }

              const value = event.message.value;
              if (value) {
                const highlights = value.documentHighlights;
                highlightReferences(highlights);
                element.dataset.documentHighlight = JSON.stringify(highlights);
                element.dataset.hoverRequestState = "finished";
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
    if (!element.dataset.referencesRequestState) {
      element.dataset.referencesRequestState = `requesting-${+element.dataset
        .lineNumber}:${+element.dataset.column}`;
      dispatchMessage("references", {
        resource: parsedUrl.resource,
        slug: parsedUrl.full_name,
        filepath: parsedUrl.filepath,
        line: +element.dataset.lineNumber,
        character: +element.dataset.column,
        text: element.innerText
      });
    }
    if (!element.dataset.documentHighlightRequestState) {
      element.dataset.documentHighlightRequestState = `requesting-${+element
        .dataset.lineNumber}:${+element.dataset.column}`;
      dispatchMessage("documentHighlight", {
        resource: parsedUrl.resource,
        slug: parsedUrl.full_name,
        filepath: parsedUrl.filepath,
        line: +element.dataset.lineNumber,
        character: +element.dataset.column,
        text: element.innerText
      });
    } else {
      if (element.dataset.documentHighlight) {
        highlightReferences(JSON.parse(element.dataset.documentHighlight));
      }
    }
  };
  document.addEventListener("mouseover", onMouseover);

  const onMouseoout = e => {
    document
      .querySelectorAll(".--sourcekit-for-safari_document-highlight")
      .forEach(element => {
        element.classList.remove("--sourcekit-for-safari_document-highlight");
        element.style.removeProperty("background-color");
      });
  };
  document.addEventListener("mouseout", onMouseoout);

  if (typeof safari !== "undefined") {
    safari.self.addEventListener("message", event => {
      handleResponse(event, parsedUrl);
    });
  }
};

let href = normalizedLocation();
window.onload = () => {
  let body = document.querySelector("body"),
    observer = new MutationObserver(mutations => {
      mutations.forEach(() => {
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
