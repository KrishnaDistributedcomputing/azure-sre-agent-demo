const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");
const vm = require("node:vm");

const html = readFileSync(path.join(__dirname, "..", "portal", "resources.html"), "utf8");
const start = html.indexOf("async function loadInventory()");
const end = html.indexOf('$("#refresh").addEventListener', start);
assert.ok(start >= 0 && end > start, "Inventory loader must exist in the page");
const loader = html.slice(start, end);

async function loadResponse(response) {
  const elements = {
    "#error": { style: {}, textContent: "" },
    "#updated": { textContent: "" }
  };
  const classes = new Set();
  const rendered = [];
  const context = vm.createContext({
    $: selector => elements[selector],
    document: {
      body: { classList: { add: name => classes.add(name), remove: name => classes.delete(name) } }
    },
    fetch: async () => response,
    inventory: null,
    dateTime: new Intl.DateTimeFormat("en-US"),
    renderMetrics: payload => rendered.push(payload),
    renderDistribution: () => {},
    fillFilters: () => {},
    renderComponents: () => {},
    renderSupporting: () => {}
  });
  await vm.runInContext(`${loader}\nloadInventory()`, context);
  assert.equal(classes.has("loading"), false);
  return { elements, rendered };
}

test("HTML 404 explains that a static server cannot serve the inventory API", async () => {
  const response = new Response("<!DOCTYPE html><title>Not found</title>", {
    status: 404,
    headers: { "Content-Type": "text/html" }
  });
  const { elements, rendered } = await loadResponse(response);
  assert.equal(elements["#error"].style.display, "block");
  assert.match(elements["#error"].textContent, /non-JSON response \(HTTP 404\)/);
  assert.match(elements["#error"].textContent, /func start/);
  assert.doesNotMatch(elements["#error"].textContent, /Unexpected token/);
  assert.equal(rendered.length, 0);
});

test("successful HTML responses are rejected rather than parsed as inventory", async () => {
  const { elements } = await loadResponse(new Response("<!DOCTYPE html>"));
  assert.match(elements["#error"].textContent, /non-JSON response \(HTTP 200\)/);
});

test("JSON API errors preserve the server error message", async () => {
  const { elements, rendered } = await loadResponse(
    Response.json({ error: "Resource Graph access denied" }, { status: 502 })
  );
  assert.match(elements["#error"].textContent, /Resource Graph access denied/);
  assert.equal(rendered.length, 0);
});

test("valid JSON inventory still renders normally", async () => {
  const payload = { generatedAt: "2026-10-14T16:00:00Z", resourceGroups: [], supportingComponents: [] };
  const { elements, rendered } = await loadResponse(Response.json(payload));
  assert.equal(elements["#error"].style.display, "none");
  assert.deepEqual(rendered, [payload]);
  assert.match(elements["#updated"].textContent, /Inventory updated/);
});
