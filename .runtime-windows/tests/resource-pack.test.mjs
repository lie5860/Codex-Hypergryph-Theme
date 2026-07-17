import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const runtimeRoot = path.resolve(here, "..");
const assets = path.join(runtimeRoot, "assets");
const [template, css, themeText] = await Promise.all([
  fs.readFile(path.join(assets, "renderer-inject.js"), "utf8"),
  fs.readFile(path.join(assets, "dream-skin.css"), "utf8"),
  fs.readFile(path.join(assets, "theme.json"), "utf8"),
]);
const theme = JSON.parse(themeText);

assert.equal(theme.id, "preset-endfield-frontier");
assert.equal(theme.appearance, "dark");
assert.equal(theme.palette.accent, "#F3C548");
assert.match(css, /grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\)\s*!important/);
for (const placeholder of ["__DREAM_CSS_JSON__", "__DREAM_ART_JSON__", "__DREAM_THEME_JSON__"]) {
  assert.equal(template.split(placeholder).length - 1, 1, `${placeholder} must appear exactly once`);
}
assert.doesNotMatch(template, /__DREAM_SKIN_(?:CSS|ART|THEME|VERSION|STYLE_REVISION)_JSON__/);

const runtimeTheme = {
  ...theme,
  artMetadata: {
    width: 2560,
    height: 1440,
    ratio: 16 / 9,
    wide: true,
    aspect: "wide",
    taskMode: "ambient",
  },
};
const payload = template
  .replace("__DREAM_CSS_JSON__", JSON.stringify(css))
  .replace("__DREAM_ART_JSON__", JSON.stringify("data:image/png;base64,AA=="))
  .replace("__DREAM_THEME_JSON__", JSON.stringify(runtimeTheme));

class ClassList {
  constructor() { this.values = new Set(); }
  add(...values) { values.forEach((value) => this.values.add(value)); }
  remove(...values) { values.forEach((value) => this.values.delete(value)); }
  contains(value) { return this.values.has(value); }
  toggle(value, enabled) {
    if (enabled) this.values.add(value);
    else this.values.delete(value);
  }
}

class StyleMap {
  constructor() { this.values = new Map(); }
  getPropertyValue(name) { return this.values.get(name) ?? ""; }
  setProperty(name, value) { this.values.set(name, value); }
  removeProperty(name) { this.values.delete(name); }
}

const nodes = new Map();
const createNode = (tagName) => {
  const attributes = new Map();
  const children = new Map();
  return {
    tagName,
    id: "",
    className: "",
    classList: new ClassList(),
    dataset: {},
    style: new StyleMap(),
    textContent: "",
    innerHTML: "",
    parentElement: null,
    getAttribute(name) { return attributes.has(name) ? attributes.get(name) : null; },
    setAttribute(name, value) { attributes.set(name, String(value)); },
    removeAttribute(name) { attributes.delete(name); },
    appendChild(node) {
      node.parentElement = this;
      if (node.id) nodes.set(node.id, node);
      return node;
    },
    remove() {
      if (this.id) nodes.delete(this.id);
      this.parentElement = null;
    },
    querySelector(selector) {
      if (!children.has(selector)) children.set(selector, createNode("span"));
      return children.get(selector);
    },
    querySelectorAll() { return []; },
    closest() { return null; },
    getBoundingClientRect() { return { left: 280, top: 36, width: 1000, height: 760 }; },
  };
};

const root = createNode("html");
root.className = "dark";
const body = createNode("body");
const main = createNode("main");
const document = {
  documentElement: root,
  head: root,
  body,
  createElement: createNode,
  getElementById(id) { return nodes.get(id) ?? null; },
  querySelector(selector) {
    if (selector === "main.main-surface" || selector === "main") return main;
    if (selector === "aside.app-shell-left-panel") return createNode("aside");
    return null;
  },
  querySelectorAll() { return []; },
};
const mediaQuery = {
  matches: true,
  addEventListener() {},
  removeEventListener() {},
};
const context = {
  window: {
    matchMedia() { return mediaQuery; },
    addEventListener() {},
    removeEventListener() {},
  },
  document,
  MutationObserver: class {
    observe() {}
    disconnect() {}
    takeRecords() { return []; }
  },
  ResizeObserver: class {
    observe() {}
    disconnect() {}
  },
  URL: {
    createObjectURL() { return "blob:endfield-test"; },
    revokeObjectURL() {},
  },
  Blob,
  Uint8Array,
  atob,
  setInterval() { return 1; },
  clearInterval() {},
  setTimeout() { return 2; },
  clearTimeout() {},
  getComputedStyle() { return { colorScheme: "dark" }; },
};

const result = vm.runInNewContext(payload, context);
assert.equal(result.installed, true);
assert.equal(result.version, "1.2.0");
assert.equal(result.themeId, "preset-endfield-frontier");
assert.equal(result.shell, "dark");
assert.equal(root.classList.contains("codex-dream-skin"), true);
assert.equal(root.getAttribute("data-dream-art-wide"), "true");
assert.equal(root.getAttribute("data-dream-art-safe"), "left");
assert.equal(root.getAttribute("data-dream-task-mode"), "ambient");
assert.equal(root.style.getPropertyValue("--ds-green"), "#F3C548");
assert.equal(root.style.getPropertyValue("--dream-skin-brand-subtitle"), '"ENDFIELD // FRONTIER PROTOCOL 01"');
assert.equal(nodes.has("codex-dream-skin-style"), true);
assert.equal(nodes.has("codex-dream-skin-chrome"), true);
assert.equal(context.window.__CODEX_DREAM_SKIN_STATE__.cleanup(), true);
assert.equal(root.classList.contains("codex-dream-skin"), false);
assert.equal(nodes.has("codex-dream-skin-style"), false);
assert.equal(nodes.has("codex-dream-skin-chrome"), false);

console.log("PASS: Endfield resource pack matches the upstream renderer contract.");
