#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const root = path.resolve(process.env.HARNESS_ROOT || ".");

const allowedPrefixes = [
  "harness.yaml",
  "agents",
  "core",
  "protocols",
  "flows",
  "wiki",
  "memory/index.yaml",
  "memory/team",
  "memory/project",
  "mcp/catalog.yaml",
  "mcp/contracts",
  "mcp/policies",
  "work/request-routing"
];

function resolveSafe(relativePath, baseRoot = root) {
  const normalized = String(relativePath || "").replace(/\\/g, "/").replace(/^\/+/, "");
  if (normalized.includes("..") || normalized.startsWith(".git/") || normalized.startsWith(".claude/agent-memory/")) {
    throw new Error("Path is outside the allowed Harness read scope.");
  }

  const allowed = allowedPrefixes.some((prefix) => normalized === prefix || normalized.startsWith(`${prefix}/`));
  if (!allowed) {
    throw new Error(`Path is not registered for Harness MCP reads: ${normalized}`);
  }

  const absolute = path.resolve(baseRoot, normalized);
  if (!absolute.startsWith(baseRoot)) {
    throw new Error("Resolved path is outside repository root.");
  }

  return absolute;
}

function readText(relativePath, baseRoot = root) {
  const absolute = resolveSafe(relativePath, baseRoot);
  const stat = fs.statSync(absolute);
  if (stat.isDirectory()) {
    const names = fs.readdirSync(absolute).sort();
    return names.join("\n");
  }
  return fs.readFileSync(absolute, "utf8");
}

function pathStatus(relativePath, baseRoot = root) {
  const absolute = path.resolve(baseRoot, relativePath);
  return {
    path: relativePath,
    exists: fs.existsSync(absolute),
    type: fs.existsSync(absolute) ? (fs.statSync(absolute).isDirectory() ? "directory" : "file") : "missing"
  };
}

function listMarkdownFiles(directory) {
  if (!fs.existsSync(directory)) return [];
  const result = [];
  const stack = [directory];
  while (stack.length > 0) {
    const current = stack.pop();
    for (const name of fs.readdirSync(current)) {
      const full = path.join(current, name);
      const stat = fs.statSync(full);
      if (stat.isDirectory()) stack.push(full);
      if (stat.isFile() && name.endsWith(".md") && name !== "index.md") result.push(full);
    }
  }
  return result.sort();
}

function statusPayload(baseRoot = root) {
  const required = [
    "CLAUDE.md",
    "AGENTS.md",
    "harness.yaml",
    "agents/registry.yaml",
    ".claude/settings.json",
    ".claude/skills",
    ".claude/agents",
    ".mcp.json",
    "protocols",
    "flows",
    "wiki",
    "memory"
  ];

  return {
    root: baseRoot,
    required: required.map((item) => pathStatus(item, baseRoot)),
    activeTasksCount: fs.existsSync(path.join(baseRoot, "work", "active"))
      ? fs.readdirSync(path.join(baseRoot, "work", "active")).filter((name) => name.endsWith(".md")).length
      : 0,
    memoryEntriesCount: listMarkdownFiles(path.join(baseRoot, "memory")).length
  };
}

function protocolList(baseRoot = root) {
  const dir = path.resolve(baseRoot, "protocols");
  return fs.readdirSync(dir)
    .filter((name) => name.endsWith(".md"))
    .sort()
    .map((name) => `protocols/${name}`)
    .join("\n");
}

function ensureDirectory(directory) {
  fs.mkdirSync(directory, { recursive: true });
}

function assertSafeId(value, name) {
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(String(value || ""))) {
    throw new Error(`${name} must start with a letter or number and contain only letters, numbers, dot, underscore, or hyphen.`);
  }
}

function slugify(value) {
  const slug = String(value || "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
  return slug || "memory";
}

function createTask(args, baseRoot = root) {
  const taskId = args.id;
  const title = args.title;
  const flow = args.flow;
  const goal = args.goal;
  const verify = args.verify || "Not specified. Add a verification command before delivery.";
  const force = Boolean(args.force);

  if (!title) throw new Error("harness_create_task requires title.");
  if (!goal) throw new Error("harness_create_task requires goal.");
  assertSafeId(taskId, "id");
  assertSafeId(flow, "flow");

  const flowPath = path.join(baseRoot, "flows", `${flow}.md`);
  if (!fs.existsSync(flowPath)) throw new Error(`Flow does not exist: flows/${flow}.md`);

  const activeDir = path.join(baseRoot, "work", "active");
  ensureDirectory(activeDir);
  const taskPath = path.join(activeDir, `${taskId}.md`);
  if (fs.existsSync(taskPath) && !force) throw new Error(`Task already exists: work/active/${taskId}.md`);

  const content = `# ${title}

Status: active

## Metadata

- ID: ${taskId}
- Flow: ${flow}
- Created: ${new Date().toISOString()}

## Goal

${goal}

## Non-goals

- Do not expand into unconfirmed scope.
- Do not perform unauthorized git or production operations.

## Execution Steps

- [ ] Load context.
- [ ] Confirm file scope.
- [ ] Implement the minimal change.
- [ ] Run verification command.
- [ ] Review changes.
- [ ] Deliver and capture required memory.

## Verification Command

\`\`\`powershell
${verify}
\`\`\`

## Risks

- Do not deliver if verification is missing or failing.
- Request user confirmation before any high-risk operation.
`;

  fs.writeFileSync(taskPath, content, "utf8");
  return { path: path.relative(baseRoot, taskPath).replace(/\\/g, "/") };
}

function captureMemory(args, baseRoot = root) {
  const layer = args.layer || "project";
  const title = args.title;
  const fact = args.fact;
  const source = args.source;
  const verified = Boolean(args.verified);

  if (!title) throw new Error("harness_capture_memory requires title.");
  if (!fact) throw new Error("harness_capture_memory requires fact.");
  if (!source) throw new Error("harness_capture_memory requires source.");

  const layerPath = {
    team: "memory/team",
    project: "memory/project",
    "claude-code": "memory/agents/claude-code",
    codex: "memory/agents/codex"
  }[layer];
  if (!layerPath) throw new Error(`Unsupported memory layer: ${layer}`);

  const directory = path.join(baseRoot, layerPath);
  ensureDirectory(directory);

  const date = new Date().toISOString().slice(0, 10);
  const slug = slugify(title);
  let filename = `${date}-${slug}.md`;
  let target = path.join(directory, filename);
  let counter = 2;
  while (fs.existsSync(target)) {
    filename = `${date}-${slug}-${counter}.md`;
    target = path.join(directory, filename);
    counter += 1;
  }

  const verification = verified ? "verified" : "unverified";
  const content = `# ${title}

- Captured: ${new Date().toISOString()}
- Layer: ${layer}
- Source: ${source}
- Verification: ${verification}

## Fact

${fact}

## Scope

Applies to this Harness Engineering workspace unless a later memory entry supersedes it.
`;

  fs.writeFileSync(target, content, "utf8");

  const indexPath = path.join(baseRoot, "memory", "index.yaml");
  ensureDirectory(path.dirname(indexPath));
  if (!fs.existsSync(indexPath)) fs.writeFileSync(indexPath, "version: 1\nrecords:\n", "utf8");
  const relativePath = path.relative(baseRoot, target).replace(/\\/g, "/");
  fs.appendFileSync(indexPath, `  - layer: ${layer}\n    title: ${title}\n    path: ${relativePath}\n    verification: ${verification}\n`, "utf8");

  return { path: relativePath };
}

function writeWorkflowFile(baseRoot, directoryName, id, content, force) {
  assertSafeId(id, "id");
  const directory = path.join(baseRoot, "work", directoryName);
  ensureDirectory(directory);
  const target = path.join(directory, `${id}.md`);
  if (fs.existsSync(target) && !force) {
    throw new Error(`Workflow artifact already exists: work/${directoryName}/${id}.md`);
  }
  fs.writeFileSync(target, content, "utf8");
  return { path: path.relative(baseRoot, target).replace(/\\/g, "/") };
}

function createBrainstorm(args, baseRoot = root) {
  const id = args.id;
  const topic = args.topic;
  const goal = args.goal;
  if (!topic) throw new Error("harness_create_brainstorm requires topic.");
  if (!goal) throw new Error("harness_create_brainstorm requires goal.");
  const content = `# Brainstorm: ${topic}

Status: active

## Metadata

- ID: ${id}
- Created: ${new Date().toISOString()}

## Goal

${goal}

## Clarifying Questions

- What is the user outcome?
- What constraints are non-negotiable?
- What does success prove?

## Candidate Approaches

- Recommended: artifact-driven workflow with explicit gates.
- Alternative: skill-only guidance.
- Alternative: agent orchestration-first workflow.

## Decision Gate

- Move to design only after the user confirms the chosen approach.
`;
  return writeWorkflowFile(baseRoot, "brainstorms", id, content, Boolean(args.force));
}

function createDesign(args, baseRoot = root) {
  const id = args.id;
  const decision = args.decision;
  const constraints = args.constraints || "No explicit constraints provided.";
  if (!decision) throw new Error("harness_create_design requires decision.");
  const content = `# Design: ${id}

Status: proposed

## Decision

${decision}

## Constraints

${constraints}

## Architecture

- Keep workflow artifacts separate from runtime-specific agent files.
- Route runtime behavior through hooks and MCP tools.
- Keep generated reports deterministic and locally verifiable.

## Verification

- Run scripts/validate-workflow-capabilities.ps1.
- Run scripts/doctor.ps1.
`;
  return writeWorkflowFile(baseRoot, "designs", id, content, Boolean(args.force));
}

function createPlan(args, baseRoot = root) {
  const id = args.id;
  const design = args.design;
  if (!design) throw new Error("harness_create_plan requires design.");
  const designPath = path.isAbsolute(design) ? design : path.join(baseRoot, design);
  if (!fs.existsSync(designPath)) throw new Error(`Design file does not exist: ${design}`);
  const content = `# Plan: ${id}

Status: ready

## Source Design

${design}

## Tasks

- [ ] Load context and confirm scope.
- [ ] Implement the smallest useful slice.
- [ ] Record checkpoints with evidence.
- [ ] Run workflow validation.
- [ ] Run full doctor validation.
- [ ] Deliver with verification evidence and residual risks.

## Verification

\`\`\`powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-workflow-capabilities.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/doctor.ps1
\`\`\`
`;
  return writeWorkflowFile(baseRoot, "plans", id, content, Boolean(args.force));
}

function updateTaskCheckpoint(args, baseRoot = root) {
  const id = args.id;
  const step = args.step;
  const evidence = args.evidence;
  assertSafeId(id, "id");
  if (!step) throw new Error("harness_update_task_checkpoint requires step.");
  if (!evidence) throw new Error("harness_update_task_checkpoint requires evidence.");

  const taskPath = path.join(baseRoot, "work", "active", `${id}.md`);
  if (!fs.existsSync(taskPath)) throw new Error(`Active task does not exist: work/active/${id}.md`);

  const timestamp = new Date().toISOString();
  fs.appendFileSync(taskPath, `

## Checkpoint ${timestamp}

- Step: ${step}
- Evidence: ${evidence}
`, "utf8");

  const logPath = path.join(baseRoot, "work", "implementation-log.md");
  ensureDirectory(path.dirname(logPath));
  if (!fs.existsSync(logPath)) fs.writeFileSync(logPath, "# Implementation Log\n", "utf8");
  fs.appendFileSync(logPath, `

## ${timestamp}

- Task: ${id}
- Step: ${step}
- Evidence: ${evidence}
`, "utf8");

  return { path: path.relative(baseRoot, logPath).replace(/\\/g, "/") };
}

function workflowStatus(args, baseRoot = root) {
  const id = args.id;
  assertSafeId(id, "id");
  const artifacts = {
    brainstorm: `work/brainstorms/${id}.md`,
    design: `work/designs/${id}.md`,
    plan: `work/plans/${id}.md`,
    task: `work/active/${id}.md`
  };
  const logPath = path.join(baseRoot, "work", "implementation-log.md");
  let checkpoints = 0;
  if (fs.existsSync(logPath)) {
    const log = fs.readFileSync(logPath, "utf8");
    checkpoints = (log.match(new RegExp(`- Task: ${id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`, "g")) || []).length;
  }
  return {
    id,
    brainstorm: { path: artifacts.brainstorm, exists: fs.existsSync(path.join(baseRoot, artifacts.brainstorm)) },
    design: { path: artifacts.design, exists: fs.existsSync(path.join(baseRoot, artifacts.design)) },
    plan: { path: artifacts.plan, exists: fs.existsSync(path.join(baseRoot, artifacts.plan)) },
    task: { path: artifacts.task, exists: fs.existsSync(path.join(baseRoot, artifacts.task)) },
    checkpoints
  };
}

function routeId(text) {
  let slug = String(text || "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
  if (slug.length > 36) slug = slug.slice(0, 36).replace(/-+$/g, "");
  if (!slug) slug = "request";
  const stamp = new Date().toISOString().replace(/[-:T.Z]/g, "").slice(0, 14);
  return `${slug}-${stamp}`;
}

function matches(text, pattern) {
  return new RegExp(pattern, "i").test(text);
}

function uniquePush(list, values) {
  for (const value of values) {
    if (!list.includes(value)) list.push(value);
  }
}

function routeRequest(args, baseRoot = root) {
  const prompt = args.prompt;
  if (!prompt) throw new Error("harness_route_request requires prompt.");

  const incidentPattern = "incident|outage|unavailable|down|production service|all users|prod.*fail|\\u7ebf\\u4e0a|\\u4e0d\\u53ef\\u7528|\\u6545\\u969c|\\u62a5\\u8b66|\\u751f\\u4ea7";
  const releasePattern = "release|deploy|deployment|publish|rollback|version|\\btag\\b|\\u53d1\\u5e03|\\u90e8\\u7f72|\\u4e0a\\u7ebf|\\u56de\\u6eda";
  const bugfixPattern = "fix|bug|error|fail|failure|failing|exception|broken|regression|\\u4fee\\u590d|\\u62a5\\u9519|\\u9519\\u8bef|\\u5931\\u8d25|\\u95ee\\u9898";
  const refactorPattern = "refactor|cleanup|clean up|restructure|simplify|architecture improvement|\\u91cd\\u6784|\\u6e05\\u7406|\\u4f18\\u5316";
  const knowledgePattern = "memory|wiki|document|documentation|docs|knowledge|capture|summary|\\u8bb0\\u5fc6|\\u77e5\\u8bc6|\\u6587\\u6863|\\u603b\\u7ed3";
  const mcpPattern = "\\bmcp\\b|model context protocol";

  let flow = "feature-development";
  let reason = "Default route for new or changed behavior.";
  if (matches(prompt, incidentPattern)) {
    flow = "incident";
    reason = "Request describes production impact, outage, or urgent failure.";
  } else if (matches(prompt, releasePattern)) {
    flow = "release";
    reason = "Request describes release, deployment, publishing, versioning, or rollback.";
  } else if (matches(prompt, bugfixPattern)) {
    flow = "bugfix";
    reason = "Request describes a bug, failure, error, or regression.";
  } else if (matches(prompt, refactorPattern)) {
    flow = "refactor";
    reason = "Request describes restructuring, cleanup, or simplification.";
  } else if (matches(prompt, knowledgePattern)) {
    flow = "knowledge-capture";
    reason = "Request primarily asks to capture or update knowledge.";
  }

  const stages = [];
  const skills = ["discover-context"];
  if (flow === "incident") {
    uniquePush(stages, ["context", "stabilize", "diagnose", "mitigate", "verify", "review", "deliver", "memory"]);
    uniquePush(skills, ["plan-work", "implement-safely", "review-changes", "capture-memory"]);
  } else if (flow === "bugfix") {
    uniquePush(stages, ["context", "reproduce", "brainstorm", "design", "plan", "implement", "verify", "review", "deliver", "memory"]);
    uniquePush(skills, ["plan-work", "implement-safely", "review-changes", "capture-memory"]);
  } else if (flow === "refactor") {
    uniquePush(stages, ["context", "design", "plan", "implement", "verify", "review", "deliver", "memory"]);
    uniquePush(skills, ["plan-work", "implement-safely", "review-changes", "capture-memory"]);
  } else if (flow === "release") {
    uniquePush(stages, ["context", "plan", "verify", "review", "release-readiness", "deliver", "memory"]);
    uniquePush(skills, ["plan-work", "review-changes", "release-readiness", "capture-memory"]);
  } else if (flow === "knowledge-capture") {
    uniquePush(stages, ["context", "classify", "capture", "verify", "deliver"]);
    uniquePush(skills, ["capture-memory", "review-changes"]);
  } else {
    uniquePush(stages, ["context", "brainstorm", "design", "plan", "implement", "verify", "review", "deliver", "memory"]);
    uniquePush(skills, ["plan-work", "implement-safely", "review-changes", "capture-memory"]);
  }
  if (matches(prompt, mcpPattern)) uniquePush(skills, ["mcp-governance"]);

  const id = routeId(prompt);
  const artifacts = [
    "work/request-routing/latest.md",
    "work/request-routing/latest.json",
    `work/brainstorms/${id}.md`,
    `work/designs/${id}.md`,
    `work/plans/${id}.md`,
    `work/active/${id}.md`
  ];
  const safeGoal = String(prompt).replace(/"/g, "'");
  const nextCommand = `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/harness.ps1 brainstorm -Id "${id}" -Topic "Request routing: ${flow}" -Goal "${safeGoal}"`;
  const route = {
    id,
    prompt,
    flow,
    reason,
    stages,
    skills,
    artifacts,
    nextCommand,
    generatedAt: new Date().toISOString()
  };
  if (!args.noWrite) writeRouteArtifacts(route, baseRoot);
  return route;
}

function writeRouteArtifacts(route, baseRoot = root) {
  const directory = path.join(baseRoot, "work", "request-routing");
  ensureDirectory(directory);
  fs.writeFileSync(path.join(directory, "latest.json"), JSON.stringify(route, null, 2), "utf8");
  const lines = [
    "# Request Routing",
    "",
    `- Generated: ${route.generatedAt}`,
    `- ID: ${route.id}`,
    `- Flow: ${route.flow}`,
    `- Reason: ${route.reason}`,
    "",
    "## Stages",
    "",
    ...route.stages.map((stage) => `- ${stage}`),
    "",
    "## Skills",
    "",
    ...route.skills.map((skill) => `- ${skill}`),
    "",
    "## Artifacts",
    "",
    ...route.artifacts.map((artifact) => `- ${artifact}`),
    "",
    "## Next Command",
    "",
    "```powershell",
    route.nextCommand,
    "```"
  ];
  fs.writeFileSync(path.join(directory, "latest.md"), lines.join("\n"), "utf8");
}

const resources = {
  "harness://harness.yaml": () => readText("harness.yaml"),
  "harness://agents/registry.yaml": () => readText("agents/registry.yaml"),
  "harness://protocols": () => protocolList()
};

function handleRequest(message) {
  const { id, method, params } = message;

  if (method === "initialize") {
    return {
      jsonrpc: "2.0",
      id,
      result: {
        protocolVersion: "2024-11-05",
        capabilities: {
          resources: {},
          tools: {}
        },
        serverInfo: {
          name: "harness",
          version: "1.0.0"
        }
      }
    };
  }

  if (method === "notifications/initialized") {
    return null;
  }

  if (method === "ping") {
    return { jsonrpc: "2.0", id, result: {} };
  }

  if (method === "resources/list") {
    return {
      jsonrpc: "2.0",
      id,
      result: {
        resources: Object.keys(resources).map((uri) => ({
          uri,
          name: uri.replace("harness://", ""),
          mimeType: "text/plain"
        }))
      }
    };
  }

  if (method === "resources/read") {
    const uri = params && params.uri;
    if (!resources[uri]) {
      throw new Error(`Unknown resource: ${uri}`);
    }
    return {
      jsonrpc: "2.0",
      id,
      result: {
        contents: [
          {
            uri,
            mimeType: "text/plain",
            text: resources[uri]()
          }
        ]
      }
    };
  }

  if (method === "tools/list") {
    return {
      jsonrpc: "2.0",
      id,
      result: {
        tools: [
          {
            name: "harness_status",
            description: "Return Harness Engineering structure status.",
            inputSchema: {
              type: "object",
              properties: {},
              additionalProperties: false
            }
          },
          {
            name: "harness_read",
            description: "Read a registered Harness Engineering file or directory.",
            inputSchema: {
              type: "object",
              properties: {
                path: {
                  type: "string",
                  description: "Repository-relative Harness path."
                }
              },
              required: ["path"],
              additionalProperties: false
            }
          },
          {
            name: "harness_create_task",
            description: "Create a local Harness task file under work/active.",
            inputSchema: {
              type: "object",
              properties: {
                id: { type: "string" },
                title: { type: "string" },
                flow: { type: "string" },
                goal: { type: "string" },
                verify: { type: "string" },
                force: { type: "boolean" }
              },
              required: ["id", "title", "flow", "goal"],
              additionalProperties: false
            }
          },
          {
            name: "harness_capture_memory",
            description: "Create a local Harness memory record and update memory/index.yaml.",
            inputSchema: {
              type: "object",
              properties: {
                layer: { type: "string", enum: ["team", "project", "claude-code", "codex"] },
                title: { type: "string" },
                fact: { type: "string" },
                source: { type: "string" },
                verified: { type: "boolean" }
              },
              required: ["title", "fact", "source"],
              additionalProperties: false
            }
          },
          {
            name: "harness_create_brainstorm",
            description: "Create a workflow brainstorm artifact under work/brainstorms.",
            inputSchema: {
              type: "object",
              properties: {
                id: { type: "string" },
                topic: { type: "string" },
                goal: { type: "string" },
                force: { type: "boolean" }
              },
              required: ["id", "topic", "goal"],
              additionalProperties: false
            }
          },
          {
            name: "harness_create_design",
            description: "Create a workflow design artifact under work/designs.",
            inputSchema: {
              type: "object",
              properties: {
                id: { type: "string" },
                decision: { type: "string" },
                constraints: { type: "string" },
                force: { type: "boolean" }
              },
              required: ["id", "decision"],
              additionalProperties: false
            }
          },
          {
            name: "harness_create_plan",
            description: "Create a workflow plan artifact under work/plans.",
            inputSchema: {
              type: "object",
              properties: {
                id: { type: "string" },
                design: { type: "string" },
                force: { type: "boolean" }
              },
              required: ["id", "design"],
              additionalProperties: false
            }
          },
          {
            name: "harness_update_task_checkpoint",
            description: "Append an implementation checkpoint to an active task and implementation log.",
            inputSchema: {
              type: "object",
              properties: {
                id: { type: "string" },
                step: { type: "string" },
                evidence: { type: "string" }
              },
              required: ["id", "step", "evidence"],
              additionalProperties: false
            }
          },
          {
            name: "harness_workflow_status",
            description: "Return workflow artifact status for a task id.",
            inputSchema: {
              type: "object",
              properties: {
                id: { type: "string" }
              },
              required: ["id"],
              additionalProperties: false
            }
          },
          {
            name: "harness_route_request",
            description: "Route a user request to a Harness flow, stages, skills, artifacts, and next command.",
            inputSchema: {
              type: "object",
              properties: {
                prompt: { type: "string" },
                noWrite: { type: "boolean" }
              },
              required: ["prompt"],
              additionalProperties: false
            }
          }
        ]
      }
    };
  }

  if (method === "tools/call") {
    const name = params && params.name;
    const args = (params && params.arguments) || {};
    if (name === "harness_status") {
      return {
        jsonrpc: "2.0",
        id,
        result: {
          content: [{ type: "text", text: JSON.stringify(statusPayload(), null, 2) }]
        }
      };
    }
    if (name === "harness_read") {
      return {
        jsonrpc: "2.0",
        id,
        result: {
          content: [{ type: "text", text: readText(args.path) }]
        }
      };
    }
    if (name === "harness_create_task") {
      return {
        jsonrpc: "2.0",
        id,
        result: {
          content: [{ type: "text", text: JSON.stringify(createTask(args), null, 2) }]
        }
      };
    }
    if (name === "harness_capture_memory") {
      return {
        jsonrpc: "2.0",
        id,
        result: {
          content: [{ type: "text", text: JSON.stringify(captureMemory(args), null, 2) }]
        }
      };
    }
    if (name === "harness_create_brainstorm") {
      return { jsonrpc: "2.0", id, result: { content: [{ type: "text", text: JSON.stringify(createBrainstorm(args), null, 2) }] } };
    }
    if (name === "harness_create_design") {
      return { jsonrpc: "2.0", id, result: { content: [{ type: "text", text: JSON.stringify(createDesign(args), null, 2) }] } };
    }
    if (name === "harness_create_plan") {
      return { jsonrpc: "2.0", id, result: { content: [{ type: "text", text: JSON.stringify(createPlan(args), null, 2) }] } };
    }
    if (name === "harness_update_task_checkpoint") {
      return { jsonrpc: "2.0", id, result: { content: [{ type: "text", text: JSON.stringify(updateTaskCheckpoint(args), null, 2) }] } };
    }
    if (name === "harness_workflow_status") {
      return { jsonrpc: "2.0", id, result: { content: [{ type: "text", text: JSON.stringify(workflowStatus(args), null, 2) }] } };
    }
    if (name === "harness_route_request") {
      return { jsonrpc: "2.0", id, result: { content: [{ type: "text", text: JSON.stringify(routeRequest(args), null, 2) }] } };
    }
    throw new Error(`Unknown tool: ${name}`);
  }

  if (method === "prompts/list") {
    return { jsonrpc: "2.0", id, result: { prompts: [] } };
  }

  throw new Error(`Unsupported method: ${method}`);
}

function makeError(id, error) {
  return {
    jsonrpc: "2.0",
    id,
    error: {
      code: -32000,
      message: error.message || String(error)
    }
  };
}

function writeMessage(message) {
  const body = JSON.stringify(message);
  process.stdout.write(`Content-Length: ${Buffer.byteLength(body, "utf8")}\r\n\r\n${body}`);
}

let buffer = "";
function consumeBuffer() {
  while (buffer.length > 0) {
    if (buffer.startsWith("Content-Length:")) {
      const headerEnd = buffer.indexOf("\r\n\r\n");
      if (headerEnd === -1) {
        return;
      }
      const header = buffer.slice(0, headerEnd);
      const match = header.match(/Content-Length:\s*(\d+)/i);
      if (!match) {
        buffer = "";
        return;
      }
      const length = Number(match[1]);
      const bodyStart = headerEnd + 4;
      if (buffer.length < bodyStart + length) {
        return;
      }
      const body = buffer.slice(bodyStart, bodyStart + length);
      buffer = buffer.slice(bodyStart + length);
      processMessage(body);
      continue;
    }

    const lineEnd = buffer.indexOf("\n");
    if (lineEnd === -1) {
      return;
    }
    const line = buffer.slice(0, lineEnd).trim();
    buffer = buffer.slice(lineEnd + 1);
    if (line.length > 0) {
      processMessage(line);
    }
  }
}

function processMessage(raw) {
  let message;
  try {
    message = JSON.parse(raw);
    const response = handleRequest(message);
    if (response) {
      writeMessage(response);
    }
  } catch (error) {
    writeMessage(makeError(message && message.id, error));
  }
}

function selfTest() {
  const required = statusPayload().required.filter((item) => !item.exists);
  if (required.length > 0) {
    throw new Error(`Missing required paths: ${required.map((item) => item.path).join(", ")}`);
  }
  const tools = handleRequest({ jsonrpc: "2.0", id: 1, method: "tools/list" });
  const names = tools.result.tools.map((tool) => tool.name);
  if (!names.includes("harness_status") || !names.includes("harness_read")) {
    throw new Error("Expected MCP tools are not registered.");
  }
  const read = handleRequest({
    jsonrpc: "2.0",
    id: 2,
    method: "tools/call",
    params: { name: "harness_read", arguments: { path: "harness.yaml" } }
  });
  if (!read.result.content[0].text.includes("HarnessEngineering")) {
    throw new Error("harness_read did not read harness.yaml.");
  }
  console.log("Harness MCP self-test passed.");
}

function selfTestActions() {
  const os = require("os");
  const testRoot = fs.mkdtempSync(path.join(os.tmpdir(), "harness-mcp-actions-"));
  ensureDirectory(path.join(testRoot, "flows"));
  fs.writeFileSync(path.join(testRoot, "flows", "feature-development.md"), "# Feature Development Flow\n", "utf8");
  ensureDirectory(path.join(testRoot, "memory"));
  fs.writeFileSync(path.join(testRoot, "memory", "index.yaml"), "version: 1\nrecords:\n", "utf8");

  const task = createTask({
    id: "mcp-action-task",
    title: "MCP action task",
    flow: "feature-development",
    goal: "Prove MCP can create Harness tasks.",
    verify: "node mcp/harness-server/server.js --self-test-actions"
  }, testRoot);
  if (!fs.existsSync(path.join(testRoot, task.path))) {
    throw new Error("MCP create task action did not create a file.");
  }

  const memory = captureMemory({
    layer: "project",
    title: "MCP action memory",
    fact: "MCP can capture local Harness memory records.",
    source: "server self-test",
    verified: true
  }, testRoot);
  if (!fs.existsSync(path.join(testRoot, memory.path))) {
    throw new Error("MCP capture memory action did not create a file.");
  }

  const status = statusPayload(testRoot);
  if (status.activeTasksCount !== 1 || status.memoryEntriesCount < 1) {
    throw new Error("MCP action status did not reflect created task and memory.");
  }

  console.log("Harness MCP action self-test passed.");
}

function selfTestWorkflow() {
  const os = require("os");
  const testRoot = fs.mkdtempSync(path.join(os.tmpdir(), "harness-mcp-workflow-"));
  ensureDirectory(path.join(testRoot, "flows"));
  fs.writeFileSync(path.join(testRoot, "flows", "feature-development.md"), "# Feature Development Flow\n", "utf8");
  createBrainstorm({ id: "wf-mcp", topic: "Workflow MCP", goal: "Create workflow artifacts through MCP." }, testRoot);
  createDesign({ id: "wf-mcp", decision: "Use MCP workflow tools.", constraints: "Local writes only." }, testRoot);
  createPlan({ id: "wf-mcp", design: "work/designs/wf-mcp.md" }, testRoot);
  createTask({
    id: "wf-mcp",
    title: "Workflow MCP task",
    flow: "feature-development",
    goal: "Track MCP workflow implementation.",
    verify: "node mcp/harness-server/server.js --self-test-workflow"
  }, testRoot);
  updateTaskCheckpoint({ id: "wf-mcp", step: "Created workflow artifacts", evidence: "self-test" }, testRoot);
  const status = workflowStatus({ id: "wf-mcp" }, testRoot);
  if (!status.brainstorm.exists || !status.design.exists || !status.plan.exists || !status.task.exists || status.checkpoints < 1) {
    throw new Error("MCP workflow self-test did not produce complete workflow status.");
  }
  console.log("Harness MCP workflow self-test passed.");
}

function selfTestRouter() {
  const os = require("os");
  const testRoot = fs.mkdtempSync(path.join(os.tmpdir(), "harness-mcp-router-"));
  const route = routeRequest({ prompt: "Fix CI failure and create a plan" }, testRoot);
  if (route.flow !== "bugfix") {
    throw new Error(`Expected bugfix flow, got ${route.flow}`);
  }
  if (!route.stages.includes("reproduce") || !route.skills.includes("implement-safely")) {
    throw new Error("Router did not include expected bugfix stages and skills.");
  }
  if (!fs.existsSync(path.join(testRoot, "work", "request-routing", "latest.json"))) {
    throw new Error("Router did not write latest.json.");
  }
  console.log("Harness MCP router self-test passed.");
}

if (process.argv.includes("--self-test")) {
  try {
    selfTest();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
  process.exit(0);
}

if (process.argv.includes("--self-test-actions")) {
  try {
    selfTestActions();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
  process.exit(0);
}

if (process.argv.includes("--self-test-workflow")) {
  try {
    selfTestWorkflow();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
  process.exit(0);
}

if (process.argv.includes("--self-test-router")) {
  try {
    selfTestRouter();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
  process.exit(0);
}

process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  buffer += chunk;
  consumeBuffer();
});
