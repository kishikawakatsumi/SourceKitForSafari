"use strict";

const host = "http://127.0.0.1:50000";

chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  const messageName = request.messageName;
  switch (messageName) {
    case "settings":
      (() => {
        const url = `${host}/${messageName}`;
        fetch(url, {
          method: "GET",
          mode: "no-cors"
        })
          .then(response => {
            return response.json();
          })
          .then(response => {
            sendResponse(JSON.stringify(response));
          })
          .catch(error => {
            console.error(`[${url}] ${error}`);
          });
      })();
      break;
    case "updateSettings":
      (() => {
        const userInfo = request.userInfo;
        const url = `${host}/${messageName}`;
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
            console.error(`[${url}] ${error}`);
          });
      })();
      break;
    case "repository":
      (() => {
        const userInfo = request.userInfo;
        const url = `${host}/${messageName}`;
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
            console.error(`[${url}] ${error}`);
          });
      })();
      break;
    default:
      (() => {
        const userInfo = request.userInfo;
        const url = `${host}/${messageName}`;
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
            console.error(`[${url}] ${error}`);
          });
      })();
      break;
  }

  return true;
});
