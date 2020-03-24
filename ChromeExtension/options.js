function saveOptions() {
  const serverPathOption = document.getElementById(
    "sourcekit-lsp.serverPathOption"
  ).value;
  const serverPath = document.getElementById("sourcekit-lsp.serverPath").value;
  const SDKOption = document.getElementById("sourcekit-lsp.SDKOption").value;
  const SDKPath = document.getElementById("sourcekit-lsp.SDKPath").value;
  const target = document.getElementById("sourcekit-lsp.target").value;
  chrome.storage.sync.set(
    {
      "sourcekit-lsp.serverPathOption": serverPathOption,
      "sourcekit-lsp.serverPath": serverPath,
      "sourcekit-lsp.SDKOption": SDKOption,
      "sourcekit-lsp.SDKPath": SDKPath,
      "sourcekit-lsp.target": target
    },
    () => {
      const userInfo = {
        "sourcekit-lsp.serverPath": serverPath,
        "sourcekit-lsp.SDKPath": SDKPath,
        "sourcekit-lsp.target": target
      };

      chrome.runtime.sendMessage({
        messageName: "options",
        userInfo: userInfo
      });
    }
  );
}

function restoreOptions() {
  chrome.storage.sync.get(
    {
      "sourcekit-lsp.serverPathOption": "default",
      "sourcekit-lsp.serverPath":
        "/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
      "sourcekit-lsp.SDKOption": "iphonesimulator",
      "sourcekit-lsp.SDKPath":
        "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator13.2.sdk",
      "sourcekit-lsp.target": "x86_64-apple-ios13-simulator"
    },
    function(items) {
      document.getElementById("sourcekit-lsp.serverPathOption").value =
        items["sourcekit-lsp.serverPathOption"];
      document.getElementById("sourcekit-lsp.serverPath").value =
        items["sourcekit-lsp.serverPath"];
      document.getElementById("sourcekit-lsp.SDKOption").value =
        items["sourcekit-lsp.SDKOption"];
      document.getElementById("sourcekit-lsp.SDKPath").value =
        items["sourcekit-lsp.SDKPath"];
      document.getElementById("sourcekit-lsp.target").value =
        items["sourcekit-lsp.target"];
    }
  );
}

document.addEventListener("DOMContentLoaded", restoreOptions);
document.getElementById("save").addEventListener("click", saveOptions);
