const $ = require("jquery");

const quickHelpElements = {};
const quickHelpTemplate = `
<div class="--sourcekit-for-safari　row">
  <div class="col-12">
    <div>
      <ul class="--sourcekit-for-safari nav nav-tabs p-2" role="tablist">
        <li class="nav-item tab-header-documentation"></li>
        <li class="nav-item tab-header-definition"></li>
        <li class="nav-item tab-header-references"></li>
      </ul>
    </div>
    <div class="tab-content"></div>
  </div>
</div>
`;

function setupQuickHelp(element, popoverContent) {
  $(element).popover({
    html: true,
    content: popoverContent,
    trigger: "manual",
    placement: "bottom",
    modifiers: [
      {
        name: "flip",
        options: {
          fallbackPlacements: ["top"]
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
      .querySelectorAll(
        ".--sourcekit-for-safari_jump-to-definition, .--sourcekit-for-safari_reference-link"
      )
      .forEach(link => {
        $(link).on("click", () => {
          hideAllQuickHelpPopovers();
        });
      });
  });
}

function setupQuickHelpContent(prefix, suffix, content, isActive) {
  const id = `quickhelp${suffix}`;
  const quickHelp = quickHelpElements[id];
  const popover = quickHelp ? $(quickHelp) : $(quickHelpTemplate);
  popover.attr("id", id);
  quickHelpElements[id] = popover;

  const activeClass = isActive ? "active" : "";

  const tabContent = document.createElement("div");
  tabContent.innerHTML = `
    <div class="tab-pane ${activeClass} overflow-auto" id="${prefix}${suffix}" role="tabpanel" aria-labelledby="${prefix}-tab">
      ${content}
    </div>
  `;

  const title = titleCase(prefix);
  $(`.tab-header-${prefix}`, popover).replaceWith(
    `
    <li class="nav-item tab-header-${prefix}">
      <a class="nav-link ${activeClass}" id="${prefix}-tab${suffix}" data-toggle="tab" href="#${prefix}${suffix}" 
         role="tab" aria-controls="${prefix}" aria-selected="${isActive}">${title}</a>
    </li>
    `
  );
  $(".nav-link", popover).attr("data-toggle", "tab");
  $(".tab-content", popover).append(tabContent.innerHTML);

  return popover;
}

function hideAllQuickHelpPopovers() {
  $(".--sourcekit-for-safari_quickhelp").popover("hide");
}

function titleCase(str) {
  return str
    .toLowerCase()
    .split(" ")
    .map(function(word) {
      return word.charAt(0).toUpperCase() + word.slice(1);
    })
    .join(" ");
}

exports.setupQuickHelp = setupQuickHelp;
exports.setupQuickHelpContent = setupQuickHelpContent;
