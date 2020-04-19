import * as path from "path";

export default class Workspace {
  static readonly root = path.join(__dirname, "..", "workspaces");

  static documentRoot(resource: string, slug: string) {
    return path.join(Workspace.root, resource, slug);
  }
}
