import * as util from "util";
import * as fs from "fs";
import * as path from "path";
import * as cp from "child_process";

import * as rpc from "vscode-jsonrpc";
import * as Protocol from "vscode-languageserver-protocol";

import Workspace from "./workspace";

const exec = util.promisify(cp.execFile);
const serverPath =
  process.platform === "darwin"
    ? cp.execSync("xcrun --find sourcekit-lsp").toString().trim()
    : cp.execSync("which sourcekit-lsp").toString().trim();

export default class LanguageServer {
  private readonly resource: string;
  private readonly slug: string;
  private readonly url: URL;
  private state = State.created;
  private connection: rpc.MessageConnection | null;

  private static readonly cache = new Map<string, LanguageServer>();

  private constructor(resource: string, slug: string, url: URL) {
    this.resource = resource;
    this.slug = slug;
    this.url = url;
    this.connection = null;
  }

  static get(resource: string, slug: string) {
    const url = new URL(
      `https://${resource.replace("/", "")}/${slug.split("/").join("/")}`
    );
    const key = url.toString();
    let instance = LanguageServer.cache.get(key);
    if (!instance) {
      instance = new LanguageServer(resource, slug, url);
      LanguageServer.cache.set(key, instance);
    }
    return instance;
  }

  async synchronizeRepository() {
    const root = Workspace.documentRoot(this.resource, this.slug);
    const host = this.url.host;
    const pathname = this.url.pathname;
    const extname = path.extname(pathname);

    try {
      await fs.promises.stat(root);
    } catch {
      await exec("git", [
        "clone",
        "--depth",
        "1",
        "--recursive",
        this.url.toString(),
        root,
      ]);
      return;
    }

    await exec("git", ["pull", "--rebase", "origin", "HEAD"], {
      cwd: root,
    });
  }

  async sendInitializeRequest() {
    if (this.state != State.created) {
      return;
    }

    this.state = State.initializing;
    const sdkPath = "";
    const target = "";

    this.connection = this.run(serverPath);

    const rootUri = Workspace.documentRoot(this.resource, this.slug);
    const capabilities = {};
    const parameters: Protocol.InitializeParams = {
      processId: process.pid,
      rootUri: rootUri,
      capabilities: capabilities,
      workspaceFolders: [],
    };

    const response = await this.connection.sendRequest(
      Protocol.InitializeRequest.type,
      parameters
    );
    await this.connection.sendNotification(
      Protocol.InitializedNotification.type
    );

    this.state = State.running;
    return response;
  }

  async sendDidOpenNotification(document: string) {
    if (this.state != State.running) {
      return;
    }
    if (!this.connection) {
      return;
    }

    const uri = path.join(
      Workspace.documentRoot(this.resource, this.slug),
      document
    );
    const languageId = "swift";
    const version = 0;
    const text = await fs.promises.readFile(uri, {
      encoding: "utf8",
    });

    const textDocument: Protocol.TextDocumentItem = {
      uri: uri,
      languageId: languageId,
      version: version,
      text: text,
    };

    const parameters: Protocol.DidOpenTextDocumentParams = {
      textDocument: textDocument,
    };
    await this.connection.sendNotification(
      Protocol.DidOpenTextDocumentNotification.type,
      parameters
    );
  }

  async sendDocumentSymbolRequest(document: string) {
    if (this.state != State.running) {
      return;
    }
    if (!this.connection) {
      return;
    }

    const uri = path.join(
      Workspace.documentRoot(this.resource, this.slug),
      document
    );
    const identifier: Protocol.TextDocumentIdentifier = {
      uri: uri,
    };

    const parameters: Protocol.DocumentSymbolParams = {
      textDocument: identifier,
    };
    return await this.connection.sendRequest(
      Protocol.DocumentSymbolRequest.type,
      parameters
    );
  }

  async sendHoverRequest(document: string, line: number, character: number) {
    if (this.state != State.running) {
      return;
    }
    if (!this.connection) {
      return;
    }

    const uri = path.join(
      Workspace.documentRoot(this.resource, this.slug),
      document
    );
    const identifier: Protocol.TextDocumentIdentifier = {
      uri: uri,
    };
    const position = Protocol.Position.create(line, character);

    const parameters: Protocol.HoverParams = {
      textDocument: identifier,
      position: position,
    };
    return await this.connection.sendRequest(
      Protocol.HoverRequest.type,
      parameters
    );
  }

  async sendDefinitionRequest(
    document: string,
    line: number,
    character: number
  ) {
    if (this.state != State.running) {
      return;
    }
    if (!this.connection) {
      return;
    }

    const uri = path.join(
      Workspace.documentRoot(this.resource, this.slug),
      document
    );
    const identifier: Protocol.TextDocumentIdentifier = {
      uri: uri,
    };
    const position = Protocol.Position.create(line, character);

    const parameters: Protocol.DefinitionParams = {
      textDocument: identifier,
      position: position,
    };
    return await this.connection.sendRequest(
      Protocol.DefinitionRequest.type,
      parameters
    );
  }

  async sendReferencesRequest(
    document: string,
    line: number,
    character: number
  ) {
    if (this.state != State.running) {
      return;
    }
    if (!this.connection) {
      return;
    }

    const uri = path.join(
      Workspace.documentRoot(this.resource, this.slug),
      document
    );
    const identifier: Protocol.TextDocumentIdentifier = {
      uri: uri,
    };
    const position = Protocol.Position.create(line, character);
    const context: Protocol.ReferenceContext = {
      includeDeclaration: false,
    };

    const parameters: Protocol.ReferenceParams = {
      textDocument: identifier,
      position: position,
      context: context,
    };
    return await this.connection.sendRequest(
      Protocol.ReferencesRequest.type,
      parameters
    );
  }

  async sendDocumentHighlightRequest(
    document: string,
    line: number,
    character: number
  ) {
    if (this.state != State.running) {
      return;
    }
    if (!this.connection) {
      return;
    }

    const uri = path.join(
      Workspace.documentRoot(this.resource, this.slug),
      document
    );
    const identifier: Protocol.TextDocumentIdentifier = {
      uri: uri,
    };
    const position = Protocol.Position.create(line, character);

    const parameters: Protocol.DocumentHighlightParams = {
      textDocument: identifier,
      position: position,
    };
    return await this.connection.sendRequest(
      Protocol.DocumentHighlightRequest.type,
      parameters
    );
  }

  private run(serverPath: string) {
    const childProcess = cp.spawn(serverPath, []);

    const connection = rpc.createMessageConnection(
      new rpc.StreamMessageReader(childProcess.stdout),
      new rpc.StreamMessageWriter(childProcess.stdin)
    );

    childProcess.stderr.on("data", (data) => {
      console.log(data);
    });

    connection.listen();

    return connection;
  }
}

enum State {
  created,
  initializing,
  running,
  closed,
}
