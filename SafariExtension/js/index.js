window.jQuery = $ = require("jquery");
require("bootstrap");

const marked = require("marked");
const GitUrlParse = require("git-url-parse");
const isReserved = require("github-reserved-names");

const hljs = require("highlight.js");
marked.setOptions({
  highlight: function (code) {
    return hljs.highlight("swift", code).value;
  },
});

const { readLines, highlightReferences } = require("./parser");
const { setupQuickHelp, setupQuickHelpContent } = require("./quickhelp");
const { symbolNavigator } = require("./symbol_navigator");
const { normalizedLocation } = require("./helper");

if (typeof chrome !== "undefined") {
  chrome.runtime.onMessage.addListener(function (message) {
    const response = JSON.parse(message);
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
          line: response.userInfo.line,
          character: response.userInfo.character,
          text: response.userInfo.text,
        },
      },
      parsedUrl
    );
  });
}

function dispatchMessage(messageName, userInfo) {
  if (typeof safari !== "undefined") {
    safari.extension.dispatchMessage(messageName, userInfo);
  } else {
    chrome.runtime.sendMessage({
      messageName: messageName,
      userInfo: userInfo,
    });
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
              const symbols = value.filter((documentSymbol) => {
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
            document.querySelectorAll(`.symbol${suffix}`).forEach((element) => {
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

                const container = document.createElement("div");
                container.classList.add(
                  "--sourcekit-for-safari_documentation-container",
                  "--sourcekit-for-safari_documentation"
                );
                container.innerHTML = documentation;

                const popoverContent = setupQuickHelpContent(
                  "documentation",
                  suffix,
                  container.outerHTML,
                  true
                );

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
            document.querySelectorAll(`.symbol${suffix}`).forEach((element) => {
              if (
                !element.dataset.definitionRequestState ||
                element.dataset.definition
              ) {
                return;
              }

              const value = event.message.value;
              if (value && value.locations) {
                const definitions = [];
                value.locations.forEach((location) => {
                  if (location.uri) {
                    const href = `${parsedUrl.protocol}://${parsedUrl.resource}/${parsedUrl.full_name}/${parsedUrl.filepathtype}/${parsedUrl.ref}/${location.uri}`;
                    definitions.push({
                      href: href,
                      path: location.uri,
                      lineNumber: location.lineNumber,
                      content: location.content,
                    });
                  } else {
                    definitions.push({
                      path: location.filename,
                      lineNumber: location.lineNumber,
                      content: location.content,
                    });
                  }
                });

                // prettier-ignore
                const definition = definitions
                  .map(definition => {
                    const href = definition.href || ""
                    const onThisFile = href.includes(parsedUrl.href);
                    const thisIsTheDefinition = onThisFile && definition.lineNumber == +element.dataset.lineNumber + 1;
                    const text = thisIsTheDefinition ? `<div class="--sourcekit-for-safari_text-bold">This is the definition</div>` : `Defined ${onThisFile ? "on" : "in"}`;
                    const linkOrText = href ?
                      `<a class="--sourcekit-for-safari_jump-to-definition --sourcekit-for-safari_text-bold" href="${href}">${thisIsTheDefinition ? "" : onThisFile ? `line ${definition.lineNumber}` : definition.path}</a>` :
                      `<span class="--sourcekit-for-safari_text-bold">${definition.path}</span>`
                    return `
                      <div class="--sourcekit-for-safari_bg-gray --sourcekit-for-safari_header">
                        ${text} ${linkOrText}
                      </div>
                      <div class="--sourcekit-for-safari_definition-header"></div>
                      ${definition.content
                        .split("\n")
                        .map((line, index) => {
                          return `
                            <div class="--sourcekit-for-safari_definition --sourcekit-for-safari_code">
                              <div class="--sourcekit-for-safari_line-number">
                                <pre><code>${definition.lineNumber + index}</code></pre>
                              </div>
                              <div>
                                <pre><code>${hljs.highlight("swift", line).value}</code></pre>
                              </div>
                            </div>
                            `;
                        })
                        .join("\n")}
                      `;
                  })
                  .join("\n");
                element.dataset.definition = definition;
                element.dataset.definitionRequestState = "finished";
                element.classList.add("--sourcekit-for-safari_quickhelp");

                const container = document.createElement("div");
                container.innerHTML = definition;

                const popoverContent = setupQuickHelpContent(
                  "definition",
                  suffix,
                  container.outerHTML,
                  false
                );

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
          (() => {
            const suffix = `-${event.message.line}-${event.message.character}`;
            document.querySelectorAll(`.symbol${suffix}`).forEach((element) => {
              if (
                !element.dataset.referencesRequestState ||
                element.dataset.references
              ) {
                return;
              }

              const value = event.message.value;
              if (value && value.locations) {
                const references = [];
                value.locations.forEach((location) => {
                  if (location.uri) {
                    const href = `${parsedUrl.protocol}://${parsedUrl.resource}/${parsedUrl.full_name}/${parsedUrl.filepathtype}/${parsedUrl.ref}/${location.uri}`;
                    references.push({
                      href: href,
                      path: location.uri,
                      lineNumber: location.lineNumber,
                      content: location.content,
                    });
                  } else {
                    references.push({
                      path: location.filename,
                      lineNumber: location.lineNumber,
                      content: location.content,
                    });
                  }
                });

                const referenceGroups = {};
                const referenceGroupHeaders = [];
                references.forEach((reference) => {
                  const hash = reference.href
                    ? new URL(reference.href).hash
                    : "";
                  const path = reference.path.replace(hash, "");
                  let references = referenceGroups[path];
                  if (!references) {
                    references = [];
                    referenceGroups[path] = references;
                    referenceGroupHeaders.push(path);
                  }
                  references.push(reference);
                });

                const numOfRefs = references.length;
                const numOfFiles = Object.keys(referenceGroups).length;
                const header = `<div class="--sourcekit-for-safari_bg-gray --sourcekit-for-safari_header">Found <span class="--sourcekit-for-safari_text-bold">${numOfRefs} references</span> in <span class="--sourcekit-for-safari_text-bold">${numOfFiles} files</span></div>`;

                const reference = referenceGroupHeaders
                  .map((groupHeader) => {
                    const group = referenceGroups[groupHeader];
                    return (
                      `<div class="--sourcekit-for-safari_reference-header --sourcekit-for-safari_text-bold">${groupHeader}</div>` +
                      group
                        .map((reference) => {
                          const code = hljs.highlight(
                            "swift",
                            reference.content
                          ).value;
                          const content = `
                            <div class="--sourcekit-for-safari_reference">
                              <div class="--sourcekit-for-safari_line-number">
                                <pre><code>${reference.lineNumber}</code></pre>
                              </div>
                              <div>
                                <pre><code>${code}</code></pre>
                              </div>
                            </div>
                            `;
                          return reference.href
                            ? `<a class="--sourcekit-for-safari_reference-link" href="${reference.href}">${content}</a>`
                            : content;
                        })
                        .join("\n")
                    );
                  })
                  .join("\n");

                const content = header + reference;
                element.dataset.references = content;
                element.dataset.referencesRequestState = "finished";
                element.classList.add("--sourcekit-for-safari_quickhelp");

                const container = document.createElement("div");
                container.innerHTML = content;

                const popoverContent = setupQuickHelpContent(
                  "references",
                  suffix,
                  container.outerHTML,
                  false
                );

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
        case "documentHighlight":
          (() => {
            const suffix = `-${event.message.line}-${event.message.character}`;
            document.querySelectorAll(`.symbol${suffix}`).forEach((element) => {
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
  if (isReserved.check(parsedUrl.owner)) {
    return;
  }

  dispatchMessage("initialize", {
    url: parsedUrl.toString("https"),
    resource: parsedUrl.resource,
    owner: parsedUrl.owner,
    name: parsedUrl.name,
    href: parsedUrl.href,
  });

  if (parsedUrl.filepathtype !== "blob") {
    return;
  }
  const supportedExtensions = [
    "swift",
    "m",
    "mm",
    "c",
    "cpp",
    "cc",
    "cxx",
    "c++",
    "h",
    "hpp",
  ];
  if (!supportedExtensions.some((ext) => parsedUrl.filepath.endsWith(ext))) {
    return;
  }

  const lines = document.querySelectorAll(".blob-code");
  const text = readLines(lines);

  dispatchMessage("didOpen", {
    resource: parsedUrl.resource,
    slug: parsedUrl.full_name,
    filepath: parsedUrl.filepath,
    text: text,
  });

  const onMouseover = (e) => {
    let element = e.target;

    if (!element.classList.contains("symbol")) {
      return;
    }
    if (
      element.dataset.parentClassList &&
      element.dataset.parentClassList.split(" ").includes("pl-c")
    ) {
      return;
    }

    const suffix = `-${+element.dataset.lineNumber}:${+element.dataset.column}`;
    const userInfo = {
      resource: parsedUrl.resource,
      slug: parsedUrl.full_name,
      filepath: parsedUrl.filepath,
      line: +element.dataset.lineNumber,
      character: +element.dataset.column,
      text: element.innerText,
    };
    if (!element.dataset.hoverRequestState) {
      element.dataset.hoverRequestState = `requesting${suffix}`;
      dispatchMessage("hover", userInfo);
    }
    if (!element.dataset.definitionRequestState) {
      element.dataset.definitionRequestState = `requesting${suffix}`;
      dispatchMessage("definition", userInfo);
    }
    if (!element.dataset.referencesRequestState) {
      element.dataset.referencesRequestState = `requesting${suffix}`;
      dispatchMessage("references", userInfo);
    }
    if (!element.dataset.documentHighlightRequestState) {
      element.dataset.documentHighlightRequestState = `requesting${suffix}`;
      dispatchMessage("documentHighlight", userInfo);
    } else {
      if (element.dataset.documentHighlight) {
        highlightReferences(JSON.parse(element.dataset.documentHighlight));
      }
    }
  };
  document.addEventListener("mouseover", onMouseover);

  const onMouseoout = (e) => {
    document
      .querySelectorAll(".--sourcekit-for-safari_document-highlight")
      .forEach((element) => {
        element.classList.remove("--sourcekit-for-safari_document-highlight");
        element.style.removeProperty("background-color");
      });
  };
  document.addEventListener("mouseout", onMouseoout);

  if (typeof safari !== "undefined") {
    safari.self.addEventListener("message", (event) => {
      handleResponse(event, parsedUrl);
    });
  }
};

(() => {
  let href = normalizedLocation();
  window.onload = () => {
    let body = document.querySelector("body"),
      observer = new MutationObserver((mutations) => {
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
      subtree: true,
    };

    observer.observe(body, config);
  };
})();

if (typeof safari !== "undefined") {
  document.addEventListener("DOMContentLoaded", (event) => {
    require("./index.css");
    activate();
  });
} else {
  activate();
}
