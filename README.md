# SourceKit for Safari

<p align="center">
  <img src="https://user-images.githubusercontent.com/40610/79199237-a7ce3480-7e6f-11ea-95b1-f836549717e1.png" width="240" />
</p>

SourceKit for Safari is a browser extension for GitHub, that enables IDE features on your browser such as symbol navigator, go to definition and documentation on hover.

<img src="https://user-images.githubusercontent.com/40610/77254137-87f98580-6ca2-11ea-96db-6d01d9df6c5d.gif" width="600" />

## Warning

This is really proof of concept code--functional proof of concept, but proof of concept nonetheless--and has not been thoroughly tested. Use at your own risk.

## Features

### Show Document Items

Bring up a list of document items, then select your desired document item to jump to the respective source code location.

<img src="https://user-images.githubusercontent.com/40610/77447255-d2aa0780-6e32-11ea-98cc-0f49aa63d9b8.png" width="400" />

### Quick Help popup

Hovering the mouse cursor over a symbol shows documentation.

<img src="https://user-images.githubusercontent.com/40610/77447411-fd945b80-6e32-11ea-8844-85270be38b91.png" width="400" />

### Jumps to Definition

If the text at the mouse cursor is a symbol defined in another file, turn it into a link navigating to the file.

<img src="https://user-images.githubusercontent.com/40610/77447572-2caacd00-6e33-11ea-9f65-aa67dc89e639.png" width="400" />

### Find References

<img src="https://user-images.githubusercontent.com/40610/78826099-eef59900-7a1b-11ea-973c-0f07bc52ff4f.png" width="400" />

Resolve project-wide references for the symbol denoted by the given text document position.

### Highlights References

Highlights all references to the symbol scoped to this file.

<img src="https://user-images.githubusercontent.com/40610/77877664-5e87bd80-7291-11ea-96c3-22759391afa3.png" width="400" />

## Installation

<img src="https://user-images.githubusercontent.com/40610/77444575-5feb5d00-6e2f-11ea-9926-9102245b9afd.png" width="64" /><img src="https://user-images.githubusercontent.com/40610/77444792-a17c0800-6e2f-11ea-9c52-8911a3acee1a.png" width="64" />

### Safari

* Download the latest `SourceKit for Safari.app` from [GitHub Releases](https://github.com/kishikawakatsumi/SourceKitForSafari/releases), run it once to install the extension.
* Open Safari - Preferences - Extension, make sure SourceKit for Safari is checked on the left panel.

### Chrome

* Download the latest `SourceKit for Safari.app` from [GitHub Releases](https://github.com/kishikawakatsumi/SourceKitForSafari/releases), run it once to install the helper app and the native messaging manifest.

* Install the extension from [Chrome Web Store](https://chrome.google.com/webstore/detail/sourcekit-for-chrome/ndfileljkldjnflefdckeiaedelndafe)

__(From version 0.6.0, Native Messaging is used to communicate with Language Protocol Server. Therefore, no longer needed to keep the host application running. The extension will automatically launch the helper application. To install the helper application, launch SourceKit for Safari.app once. Then the helper application will be installed.)__

~~(Unlike Safari Extension, Chrome Extension communicates with the language server through the host application. Therefore, the host application must be running while using the extension.)~~

## Getting Started

SourceKit for Safari depends on [SourceKit-LSP](https://github.com/apple/sourcekit-lsp). In order to use SourceKit for Safari, you need to install SourceKit-LSP and set the installation location.

If you have installed Xcode 11.4+ or the corresponding Command Line Tools package, the SourceKit-LSP server is included and can be run with `xcrun sourcekit-lsp`.

If you are using a toolchain from Swift.org, the SourceKit-LSP server is included and can be run with `xcrun --toolchain swift sourcekit-lsp`.

If your toolchain did not come with SourceKit-LSP, you should [build it from source](https://github.com/apple/sourcekit-lsp/blob/master/Documentation/Development.md).

SourceKit for Safari uses SourceKit-LSP that comes with Xcode 11.4 by default.

```
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp
```
If you want to use other SourceKit-LSP binary, click the toolbar icon and set its full path to the settings text field.

<img src="https://user-images.githubusercontent.com/40610/78082996-5180e080-73ef-11ea-8bf7-0034720489ec.png" width="600" />

(for Chrome users)

<img src="https://user-images.githubusercontent.com/40610/78083215-cbb16500-73ef-11ea-92a4-5759c496b811.png" width="400">

Hover over symbols in the source code; then, the documentation for that symbol a popup will show or turn it link to the definition (The first may take some time).

## How it works

SourceKit for Safari will automatically clone a GitHub repository to your local filesystem (`~/Library/Group Containers/$(TeamIdentifierPrefix).com.kishikawakatsumi.SourceKitForSafari`) when you access there.

Then, when the source file is displayed on the browser, it automatically communicates with SourceKit-LSP to get information about the source code. Then show them with a popup on the browser.

SourceKit for Safari does not automatically update local repositories.

If the local repository is outdated, click the toolbar icon and press the Sync button to update it.

## Troubleshooting

### Chrome extension doesn't work

Make sure the host application (`SourceKit for Safari.app`) is running. Chrome extension requires the host application to communicate to the language server.

## Development

To use [Node Packaged Modules](https://www.npmjs.com/) in injected scripts, it requires to combine multiple modules and JavaScript files into one JavaScript file using [Browserify](http://browserify.org/).

To do that, run the following commands in `Terminal.app`. (Node.js development environment such as `npm` command must be set up in advance.)

```shell
cd ./SafariExtension/js
npm install
npm run build
```

Please make sure to perform clean build when you change injected JavaScript or CSS files. Otherwise, the changes will not install correctly.

## References

- [SourceKit-LSP](https://github.com/apple/sourcekit-lsp)
- [Safari App Extensions](https://developer.apple.com/documentation/safariservices/safari_app_extensions)
- [Language Server Protocol Specification](https://microsoft.github.io/language-server-protocol/specifications/specification-current/)
