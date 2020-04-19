import * as Express from "express";
import * as BodyParser from "body-parser";
import * as Compression from "compression";

import LanguageServer from "./languageServer";

const app = Express();

app.use(Compression());
app.use(BodyParser.urlencoded({ extended: false }));
app.use(BodyParser.json());

app.get("/", (req, res) => {
  res.status(200).json({ request: null, result: "success" });
});

app.post("/initialize", function (req, res, next) {
  (async () => {
    const resource: string = req.body.resource;
    const slug: string = req.body.slug;

    const server = LanguageServer.get(resource, slug);
    await server.synchronizeRepository();

    res.status(200).json({ request: "initialize", result: "success" });
  })().catch(next);
});

app.post("/didOpen", function (req, res, next) {
  (async () => {
    const resource: string = req.body.resource;
    const slug: string = req.body.slug;
    const document: string = req.body.document;

    const server = LanguageServer.get(resource, slug);

    await server.sendInitializeRequest();
    await server.sendDidOpenNotification(document);

    res.status(200).json({ request: "didOpen", result: "success" });
  })().catch(next);
});

app.post("/documentSymbol", function (req, res, next) {
  (async () => {
    const resource: string = req.body.resource;
    const slug: string = req.body.slug;
    const document: string = req.body.document;

    const server = LanguageServer.get(resource, slug);
    const response = await server.sendDocumentSymbolRequest(document);

    res
      .status(200)
      .json({ request: "documentSymbol", result: "success", value: response });
  })().catch(next);
});

app.post("/hover", function (req, res, next) {
  (async () => {
    const resource: string = req.body.resource;
    const slug: string = req.body.slug;
    const document: string = req.body.document;
    const line = req.body.line;
    const character = req.body.character;

    const server = LanguageServer.get(resource, slug);
    const response = await server.sendHoverRequest(document, line, character);

    res
      .status(200)
      .json({ request: "hover", result: "success", value: response });
  })().catch(next);
});

app.post("/definition", function (req, res, next) {
  (async () => {
    const resource: string = req.body.resource;
    const slug: string = req.body.slug;
    const document: string = req.body.document;
    const line = req.body.line;
    const character = req.body.character;

    const server = LanguageServer.get(resource, slug);
    const response = await server.sendDefinitionRequest(
      document,
      line,
      character
    );

    res
      .status(200)
      .json({ request: "definition", result: "success", value: response });
  })().catch(next);
});

app.post("/references", function (req, res, next) {
  (async () => {
    const resource: string = req.body.resource;
    const slug: string = req.body.slug;
    const document: string = req.body.document;
    const line = req.body.line;
    const character = req.body.character;

    const server = LanguageServer.get(resource, slug);
    const response = await server.sendReferencesRequest(
      document,
      line,
      character
    );

    res
      .status(200)
      .json({ request: "references", result: "success", value: response });
  })().catch(next);
});

app.post("/documentHighlight", function (req, res, next) {
  (async () => {
    const resource: string = req.body.resource;
    const slug: string = req.body.slug;
    const document: string = req.body.document;
    const line = req.body.line;
    const character = req.body.character;

    const server = LanguageServer.get(resource, slug);
    const response = await server.sendDocumentHighlightRequest(
      document,
      line,
      character
    );

    res.status(200).json({
      request: "documentHighlight",
      result: "success",
      value: response,
    });
  })().catch(next);
});

app.listen(process.env.PORT || 3000);
