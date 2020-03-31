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

exports.setupQuickHelp = setupQuickHelp;
exports.setupQuickHelpContent = setupQuickHelpContent;
