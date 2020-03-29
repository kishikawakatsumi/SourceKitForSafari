const GitUrlParse = require("git-url-parse");

document.addEventListener("DOMContentLoaded", () => {
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
    function(items) {
      fillIn(items);
      updateUI();
    }
  );

  getSettings();

  document.getElementById("server").addEventListener("change", () => {
    saveSettings();
  });
  document.getElementById("server_path").addEventListener("input", () => {
    saveSettings();
  });
  document.getElementById("sdk").addEventListener("change", () => {
    saveSettings();
  });
  document.getElementById("target").addEventListener("input", () => {
    saveSettings();
  });
  document.getElementById("toolchain").addEventListener("input", () => {
    saveSettings();
  });
  document.getElementById("auto_checkout").addEventListener("change", () => {
    saveSettings();
  });
  document
    .getElementById("access_token_github")
    .addEventListener("input", () => {
      saveSettings();
    });

  chrome.tabs.query({ active: true, currentWindow: true }, tabs => {
    var tab = tabs[0];

    const parsedUrl = GitUrlParse(tab.url);
    if (!parsedUrl) {
      return;
    }
    if (parsedUrl.resource !== "github.com") {
      return;
    }
    if (!parsedUrl.owner || !parsedUrl.name) {
      return;
    }

    const parser = new URL(parsedUrl.toString("https"));
    const pathComponents = parser.pathname.split("/");
    if (pathComponents.length >= 3) {
      const url = `https://${parsedUrl.resource}${pathComponents
        .slice(0, 3)
        .join("/")}.git`;
      document.getElementById("current_repository").innerText = url;

      chrome.runtime.sendMessage(
        { messageName: "repository", userInfo: { url: url } },
        res => {
          const response = JSON.parse(res);
          if (response.result !== "success") {
            return;
          }

          document.getElementById("local_checkout_directory").innerText =
            response.value.localCheckoutDirectory;
          document.getElementById("last_update").innerText =
            response.value.lastUpdate;

          document.getElementById("sync_repository_button").disabled = false;

          document
            .getElementById("sync_repository_button")
            .addEventListener("click", () => {
              chrome.runtime.sendMessage(
                { messageName: "checkoutRepository", userInfo: { url: url } },
                res => {
                  const response = JSON.parse(res);
                  if (response.result !== "success") {
                    return;
                  }

                  document.getElementById(
                    "local_checkout_directory"
                  ).innerText = response.value.localCheckoutDirectory || "";
                  document.getElementById("last_update").innerText =
                    response.value.lastUpdate || "";

                  document.getElementById(
                    "sync_repository_button"
                  ).disabled = false;
                }
              );
            });
        }
      );
    }
  });
});

function updateUI() {
  const server = document.getElementById("server");
  if (server.value == "default") {
    const server_path = document.getElementById("server_path");
    server_path.disabled = true;
  } else {
    const server_path = document.getElementById("server_path");
    server_path.disabled = false;
  }

  const sdk_path = document.getElementById("sdk_path");
  sdk_path.disabled = true;
}

function fillIn(items) {
  const allKeys = Object.keys(items);
  allKeys.forEach(key => {
    const element = document.getElementById(key);
    if (element) {
      if (key === "auto_checkout") {
        element.checked = items[key];
      } else {
        element.value = `${items[key]}`;
      }
    }
  });
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

function saveSettings() {
  const userInfo = {};

  const server = document.getElementById("server");
  userInfo["server"] = server.value;

  if (server.value == "custom") {
    const server_path = document.getElementById("server_path");
    userInfo["server_path"] = server_path.value;
  }

  const sdk = document.getElementById("sdk");
  userInfo["sdk"] = sdk.value;

  const target = document.getElementById("target");
  userInfo["target"] = target.value;

  const toolchain = document.getElementById("toolchain");
  userInfo["toolchain"] = toolchain.value;

  const auto_checkout = document.getElementById("auto_checkout");
  userInfo["auto_checkout"] = auto_checkout.checked;

  const access_token_github = document.getElementById("access_token_github");
  userInfo["access_token_github"] = access_token_github.value;

  chrome.storage.sync.set(userInfo, () => {
    postSettings(userInfo);
  });
}
