"use strict";

const application = "com.kishikawakatsumi.sourcekit_for_safari";

const port = chrome.runtime.connectNative(application);

port.onMessage.addListener((response) => {
  chrome.tabs.sendMessage(response.tabId, JSON.stringify(response));
});

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (sender.tab) {
    port.postMessage({
      messageName: request.messageName,
      userInfo: request.userInfo,
      tabId: sender.tab.id,
    });
  } else {
    chrome.runtime.sendNativeMessage(
      application,
      {
        messageName: request.messageName,
        userInfo: request.userInfo,
        tabId: 0,
      },
      (response) => {
        sendResponse(JSON.stringify(response));
      }
    );
  }
  return true;
});
