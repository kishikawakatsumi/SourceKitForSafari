window.jQuery = $ = require("jquery");
require("bootstrap");

const tippy = require("tippy.js");
const marked = require("marked");
marked.setOptions({
  highlight: function(code) {
    return hljs.highlight("swift", code).value;
  }
});
const hljs = require("highlight.js");
const GitUrlParse = require("git-url-parse");

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
const quickHelpElements = {};

const normalizedLocation = () => {
  return document.location.href.replace(/#.*$/, "");
};

const readLine = (line, lineIndex, columnIndex) => {
  let nodes = line.childNodes;
  for (var i = 0; i < nodes.length; i++) {
    const node = nodes[i];
    if (node.nodeName === "#text") {
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
};

const readLines = lines => {
  const contents = [];
  lines.forEach((line, index) => {
    contents.push(line.innerText.replace(/^[\r\n]+|[\r\n]+$/g, ""));
    readLine(line, index, 0);
  });
  return contents.join("\n");
};

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
  safari.extension.dispatchMessage("initialize", {
    resource: parsedUrl.resource,
    href: parsedUrl.href
  });

  if (parsedUrl.filepathtype !== "blob") {
    return;
  }

  const lines = document.querySelectorAll(".blob-code");
  const text = readLines(lines);

  safari.extension.dispatchMessage("didOpen", {
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
      element.dataset.hoverRequestState = "requesting";
      safari.extension.dispatchMessage("hover", {
        resource: parsedUrl.resource,
        slug: parsedUrl.full_name,
        filepath: parsedUrl.filepath,
        line: +element.dataset.lineNumber,
        character: +element.dataset.column,
        text: element.innerText
      });
    }
    if (!element.dataset.definitionRequestState) {
      element.dataset.definitionRequestState = "requesting";
      safari.extension.dispatchMessage("definition", {
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

  let codeNavigation;
  safari.self.addEventListener("message", event => {
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

            const blobCodeInner = document.querySelector(".blob-code-inner");
            const style = getComputedStyle(blobCodeInner);

            const navigationContainer = document.createElement("div");
            navigationContainer.classList.add(
              "--sourcekit-for-safari_symbol-navigation",
              "row"
            );
            const navigationLayoutColumn = document.createElement("div");
            navigationLayoutColumn.classList.add("overflow-auto", "col-12");

            navigationContainer.appendChild(navigationLayoutColumn);

            const symbolNavigation = document.createElement("ul");
            symbolNavigation.classList.add(
              "--sourcekit-for-safari_symbol-navigation-list"
            );
            symbolNavigation.style.cssText = `list-style: none; font-family: ${style.fontFamily}; font-size: ${style.fontSize};`;

            navigationLayoutColumn.appendChild(symbolNavigation);

            symbols.forEach(documentSymbol => {
              if (!isNaN(documentSymbol.kind)) {
                return;
              }

              const symbolImages = {
                s: `${safari.extension.baseURI}S@3x.png"`,
                c: `${safari.extension.baseURI}C@3x.png"`,
                i: `${safari.extension.baseURI}I@3x.png"`,
                p: `${safari.extension.baseURI}P@3x.png"`,
                m: `${safari.extension.baseURI}M@3x.png"`,
                f: `${safari.extension.baseURI}F@3x.png"`,
                e: `${safari.extension.baseURI}E@3x.png"`
              };

              const navigationItem = document.createElement("li");
              navigationItem.style.cssText = "margin: 10px 0;";
              const symbolLetter = documentSymbol.kind.slice(0, 1);
              const imageData = symbolImages[symbolLetter];
              const img = imageData
                ? `<img src="${imageData}" width="16" height="16" align="center" />`
                : symbolLetter.toUpperCase();
              navigationItem.innerHTML = `<a href="${
                parsedUrl.href
              }#L${documentSymbol.start.line + 1}">${img} ${
                documentSymbol.name
              }</a>`;
              symbolNavigation.appendChild(navigationItem);
            });

            codeNavigation = tippy(document.querySelector(".blob-wrapper"), {
              content: navigationContainer,
              interactive: true,
              arrow: false,
              animation: false,
              duration: 0,
              placement: "right-start",
              offset: [0, -80],
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
          const element = document.querySelector(`.symbol${suffix}`);
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

            const popoverContent = (() => {
              const id = `quickhelp${suffix}`;
              const quickHelp = quickHelpElements[id];
              const popover = quickHelp ? $(quickHelp) : $(quickHelpTemplate);
              popover.attr("id", id);
              quickHelpElements[id] = popover;
              return popover;
            })();

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
                $(".--sourcekit-for-safari_quickhelp").popover("hide");
              });
              $(element).on("shown.bs.popover", function() {
                const navs = document.querySelectorAll(".nav-link");
                navs.forEach(nav => {
                  nav.dataset.toggle = "tab";
                });
              });
            }
          }
        })();
        break;
      case "definition":
        (() => {
          const suffix = `-${event.message.line}-${event.message.character}`;
          const element = document.querySelector(`.symbol${suffix}`);
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
              const href = `${parsedUrl.protocol}://${parsedUrl.resource}/${parsedUrl.full_name}/${parsedUrl.filepathtype}/${parsedUrl.ref}/${location.uri}`;
              definitions.push({
                href: href,
                path: location.uri,
                content: location.content
              });
            });

            const definition = definitions
              .map(definition => {
                const referenceLineNumber = definition.href
                  .replace(parsedUrl.href, "")
                  .replace("#L", "");
                const onThisFile = definition.href.includes(parsedUrl.href);
                const thisIsTheDefinition =
                  onThisFile &&
                  referenceLineNumber == +element.dataset.lineNumber + 1;
                const text = thisIsTheDefinition
                  ? `<div class="--sourcekit-for-safari_text-bold">This is the definition</div>`
                  : `Defined ${onThisFile ? "on" : "in"}`;
                return `<div class="--sourcekit-for-safari_bg-gray">${text} <a class="--sourcekit-for-safari_text-bold" href="${
                  definition.href
                }">${
                  thisIsTheDefinition
                    ? ""
                    : onThisFile
                    ? `line ${referenceLineNumber}`
                    : definition.path
                }</a></div><div><pre class="--sourcekit-for-safari_code"><code>${
                  hljs.highlight("swift", definition.content).value
                }</code></pre></div>`;
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

            const popoverContent = (() => {
              const id = `quickhelp${suffix}`;
              const quickHelp = quickHelpElements[id];
              const popover = quickHelp ? $(quickHelp) : $(quickHelpTemplate);
              popover.attr("id", id);
              quickHelpElements[id] = popover;
              return popover;
            })();

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
                $(".--sourcekit-for-safari_quickhelp").popover("hide");
              });
              $(element).on("shown.bs.popover", function() {
                const navs = document.querySelectorAll(".nav-link");
                navs.forEach(nav => {
                  nav.dataset.toggle = "tab";
                });
              });
            }
          }
        })();
        break;
      default:
        break;
    }
  });
};

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

document.addEventListener("DOMContentLoaded", event => {
  require("./index.css");
  activate();
});
