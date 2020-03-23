"use strict";

chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  let messageName = request.messageName;
  let userInfo = request.userInfo;
  var url = `http://127.0.0.1:50000/${messageName}`;
  fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json; charset=utf-8"
    },
    body: JSON.stringify(userInfo),
    mode: "no-cors"
  })
    .then(response => {
      return response.json();
    })
    .then(response => {
      sendResponse(JSON.stringify(response));
    })
    .catch(error => {
      console.error(error);
    });
  return true;
});
