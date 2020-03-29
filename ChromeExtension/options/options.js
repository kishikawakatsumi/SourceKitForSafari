document.addEventListener("DOMContentLoaded", () => {
  chrome.storage.onChanged.addListener(() => {
    chrome.storage.sync.get(
      {
        server: "default",
        server_path:
          "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
        sdk: "iphonesimulator",
        sdk_path:
          "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk",
        target: "x86_64-apple-ios13-simulator",
        toolchain: "",
        auto_checkout: true,
        access_token_github: ""
      },
      items => {
        fillIn(items);
        updateUI();
        postSettings(items);
      }
    );
  });

  chrome.storage.sync.get(
    {
      server: "default",
      server_path:
        "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
      sdk: "iphonesimulator",
      sdk_path:
        "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk",
      target: "x86_64-apple-ios13-simulator",
      toolchain: "",
      auto_checkout: true,
      access_token_github: ""
    },
    items => {
      fillIn(items);
      updateUI();
      getSettings();
    }
  );
});

function updateUI() {
  const selectElements = document.querySelectorAll("select");
  const inputElements = document.querySelectorAll("input");
  inputElements[0].disabled = selectElements[0].value == "default";
}

function fillIn(items) {
  const selectElements = document.querySelectorAll("select");
  const inputElements = document.querySelectorAll("input");

  selectElements[0].value = items["server"];
  inputElements[0].value = items["server_path"];

  selectElements[1].value = items["sdk"];
  inputElements[1].value = items["sdk_path"];

  inputElements[2].value = items["target"];

  inputElements[3].value = items["toolchain"];

  inputElements[4].checked = items["auto_checkout"];

  inputElements[5].value = items["access_token_github"];
}

function getSettings() {
  chrome.runtime.sendMessage({ messageName: "settings" }, res => {
    const response = JSON.parse(res);
    if (response.result !== "success") {
      return;
    }

    fillIn(response.value);
    updateUI();
  });
}

function postSettings(items) {
  chrome.runtime.sendMessage(
    {
      messageName: "updateSettings",
      userInfo: items
    },
    () => {
      getSettings();
    }
  );
}

chrome.options.set([
  { type: "h3", desc: "Language Server" },
  {
    type: "row",
    options: [
      {
        name: "server",
        type: "select",
        default: "default",
        desc: "SourceKit-LSP",
        options: [
          { value: "default", desc: "Default" },
          { value: "custom", desc: "Custom" }
        ]
      },
      {
        name: "server_path",
        type: "text",
        desc: "Path",
        disabled: true,
        singleline: true
      }
    ]
  },
  {
    type: "row",
    options: [
      {
        name: "sdk",
        type: "select",
        default: "iphonesimulator",
        desc: "SDK",
        options: [
          { value: "iphonesimulator", desc: "iOS" },
          { value: "macosx", desc: "macOS" },
          { value: "watchsimulator", desc: "watchOS" },
          { value: "appletvsimulator", desc: "tvOS" }
        ]
      },
      {
        type: "text",
        name: "sdk_path",
        desc: "Path",
        disabled: true,
        singleline: true
      }
    ]
  },
  {
    type: "row",
    options: [
      {
        name: "target",
        type: "text",
        desc: "Target",
        singleline: true
      }
    ]
  },
  {
    type: "row",
    options: [
      {
        name: "toolchain",
        type: "text",
        desc: "Toolchain",
        singleline: true
      }
    ]
  },
  { type: "h3", desc: "GitHub" },
  {
    type: "row",
    options: [
      {
        type: "checkbox",
        name: "auto_checkout",
        desc: "Automatically checkout the repository when you visit"
      }
    ]
  },
  {
    type: "row",
    options: [
      {
        name: "access_token_github",
        type: "text",
        desc: "Personal Access Token",
        singleline: true
      }
    ]
  }
]);
