# SourceKit for Safari

SourceKit for Safari is a Safari extension for GitHub, that enables IDE features like go to definition, or documentation on hover.

<img src="https://user-images.githubusercontent.com/40610/77254137-87f98580-6ca2-11ea-96db-6d01d9df6c5d.gif" width="600" />

## Warning

This is really proof of concept code--functional proof of concept, but proof of concept nonetheless--and has not been thoroughly tested. Use at your own risk.


## Features

### Show Document Items

Bring up a list of document items, then select your desired document item to jump to the respective source code location.

<img src="https://user-images.githubusercontent.com/40610/76712085-b7ffd080-6758-11ea-8506-8863d496e5b5.png" width="400" />

### Quick Help popup

Hovering the mouse cursor over a symbol shows documentation.

<img src="https://user-images.githubusercontent.com/40610/77254202-ffc7b000-6ca2-11ea-9fb1-ce0e16f8e09e.png" width="400" />

### Jumps to Definition

If the text at the mouse cursor is a symbol defined in another file, turn it into a link navigating to the file.

<img src="https://user-images.githubusercontent.com/40610/77254205-022a0a00-6ca3-11ea-840f-d54d6a8baa10.png" width="400" />

## Installation

* Download the latest `SourceKit for Safari.app` from [GitHub Releases](https://github.com/kishikawakatsumi/SourceKitForSafari/releases), run it once to install the extension.
* Open Safari - Preferences - Extension, make sure SourceKit for Safari is checked on the left panel.


## Getting Started

SourceKit for Safari depends on [SourceKit-LSP](https://github.com/apple/sourcekit-lsp). In order to use SourceKit for Safari, you need to install SourceKit-LSP and set the installation location.

If you have installed Xcode 11.4+ or the corresponding Command Line Tools package, the SourceKit-LSP server is included and can be run with `xcrun sourcekit-lsp`.

If you are using a toolchain from Swift.org, the SourceKit-LSP server is included and can be run with `xcrun --toolchain swift sourcekit-lsp`.

If your toolchain did not come with SourceKit-LSP, you should [build it from source](https://github.com/apple/sourcekit-lsp/blob/master/Documentation/Development.md).

SourceKit for Safari uses SourceKit-LSP that comes with Xcode 11.4 beta by default.

```
/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp
```
If you want to use other SourceKit-LSP binary, click the toolbar icon and set its full path to the settings text field.

<img src="https://user-images.githubusercontent.com/40610/76707770-7e699e00-6735-11ea-93a7-0f24b07e290d.png" width="600" />

Hover over symbols in the source code; then, the documentation for that symbol a popup will show or turn it link to the definition (The first may take some time).

## How it works

SourceKit for Safari will automatically clone a GitHub repository to your local filesystem (`~/Library/Group Containers/27AEDK3C9F.com.kishikawakatsumi.SourceKitForSafari`) when you access there.

Then, when the source file is displayed on the browser, it automatically communicates with SourceKit-LSP to get information about the source code. Then show them with a popup on the browser.

SourceKit for Safari does not automatically update local repositories.

If the local repository is outdated, click the toolbar icon and press the Sync button to update it.


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
