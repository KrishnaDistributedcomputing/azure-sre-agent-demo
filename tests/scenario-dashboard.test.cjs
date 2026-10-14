const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");
const vm = require("node:vm");

const expectedScenarios = [
  "http-500", "latency", "dependency-failure", "throttling", "queue-backlog",
  "poison-message", "memory-pressure", "cpu-saturation", "config-drift", "deployment-regression"
];
const html = readFileSync(path.join(__dirname, "..", "portal", "index.html"), "utf8");
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const startup = script.indexOf('$("#refresh").addEventListener');
assert.ok(startup > 0);

class Element {
  constructor(tag) {
    this.tag = tag;
    this.children = [];
    this.attributes = {};
    this.dataset = {};
    this.style = {};
    this.textContent = "";
  }
  append(...children) { this.children.push(...children); }
  replaceChildren(...children) { this.children = children; }
  setAttribute(name, value) { this.attributes[name] = value; }
  addEventListener() {}
  scrollIntoView() {}
}

function loadPage() {
  const roots = {
    "#scenarios": new Element("div"),
    "#scenario-detail": new Element("article")
  };
  const context = vm.createContext({
    document: {
      querySelector: selector => roots[selector],
      querySelectorAll: () => [],
      createElement: tag => new Element(tag),
      createElementNS: (_namespace, tag) => new Element(tag)
    }
  });
  vm.runInContext(`${script.slice(0, startup)}
    globalThis.api = {
      scenarioDetails, scenarioPlaybooks, renderScenarios, showScenarioDetail,
      scenarioAgentPrompt, scenarioReportPrompt, scenarioQuery
    };`, context);
  return { api: context.api, roots };
}

function descendants(node) {
  return [node, ...node.children.flatMap(descendants)];
}

test("all ten registered business scenarios have a complete playbook", () => {
  const { api } = loadPage();
  assert.deepEqual(Object.keys(api.scenarioDetails), expectedScenarios);
  assert.deepEqual(Object.keys(api.scenarioPlaybooks), expectedScenarios);
});

for (const name of expectedScenarios) {
  test(`${name} renders Azure roles, sample dashboards, and actionable Agent templates`, () => {
    const { api, roots } = loadPage();
    api.showScenarioDetail(name);
    const nodes = descendants(roots["#scenario-detail"]);
    const text = nodes.map(node => node.textContent).join("\n");
    const charts = nodes.filter(node => node.tag === "svg");
    assert.ok(nodes.filter(node => node.className === "component-role").length >= 5);
    assert.equal(charts.length, 3);
    charts.forEach(chart => {
      assert.equal(chart.attributes.role, "img");
      assert.match(chart.attributes["aria-label"], /Illustrative sample.*Before:.*Incident:.*Recovered:/);
      assert.equal(chart.children.filter(node => node.tag === "rect").length, 3);
    });
    assert.match(text, /Illustrative sample data only/);
    assert.match(text, /Demo evidence boundary:/);
    assert.match(text, /not a live Agent session/);
    assert.match(text, /No|no|not/);
    assert.match(api.scenarioAgentPrompt(name), /read-only tools/);
    assert.match(api.scenarioAgentPrompt(name), /human approval/);
    assert.match(api.scenarioReportPrompt(name), /Not instrumented/);
    assert.match(api.scenarioReportPrompt(name), /no Live Report has been created/);
    assert.ok(api.scenarioQuery(name).includes(`== "${name}"`));
  });
}

test("samples remain available while live telemetry is unavailable", () => {
  const { api, roots } = loadPage();
  api.renderScenarios(expectedScenarios.map(scenario => ({
    scenario, count: 0, status: "unavailable"
  })));
  assert.equal(roots["#scenarios"].children.length, 10);
  assert.equal(
    descendants(roots["#scenarios"]).filter(node => node.textContent === "Awaiting telemetry").length,
    10
  );
  assert.match(
    descendants(roots["#scenario-detail"]).map(node => node.textContent).join("\n"),
    /Sample dashboard: Checkout HTTP 500/
  );
});

test("queue, memory, configuration, and release limits do not claim unmeasured recovery", () => {
  const { api } = loadPage();
  assert.match(api.scenarioPlaybooks["queue-backlog"].limits, /not current queue depth/);
  assert.match(api.scenarioPlaybooks["poison-message"].limits, /does not.*retry/);
  assert.match(api.scenarioPlaybooks["memory-pressure"].limits, /does not establish a leak/);
  assert.match(api.scenarioDetails["config-drift"].success, /rerunning config-drift/);
  assert.match(api.scenarioDetails["deployment-regression"].success, /intentionally HTTP 500/);
});
