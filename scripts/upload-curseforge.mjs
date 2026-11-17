/**
 * Package Forever Vendetta and upload the zip to CurseForge for moderation.
 *
 * One-time setup:
 *   1. Create the CurseForge project (WoW → Forever Vendetta).
 *   2. Copy curseforge.example.json → curseforge.json and set projectId.
 *   3. Copy .env.example → .env and set CURSEFORGE_API_TOKEN
 *      from https://www.curseforge.com/account/api-tokens
 *
 * Usage:
 *   node scripts/upload-curseforge.mjs
 *   node scripts/upload-curseforge.mjs --dry-run
 *   node scripts/upload-curseforge.mjs --list-versions
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");

function loadDotEnv() {
  const p = path.join(root, ".env");
  if (!fs.existsSync(p)) return;
  const raw = fs.readFileSync(p, "utf8").replace(/^\uFEFF/, "");
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const m = trimmed.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!m) continue;
    let v = m[2].trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.slice(1, -1);
    }
    if (process.env[m[1]] == null || process.env[m[1]] === "") process.env[m[1]] = v;
  }
}

function hasFlag(flag) {
  return process.argv.includes(flag);
}

function loadConfig() {
  const cfgPath = path.join(root, "curseforge.json");
  if (!fs.existsSync(cfgPath)) {
    throw new Error("Missing curseforge.json — copy curseforge.example.json and set projectId.");
  }
  return JSON.parse(fs.readFileSync(cfgPath, "utf8"));
}

function readVersion() {
  const toc = fs.readFileSync(path.join(root, "ForeverVendetta.toc"), "utf8");
  const m = toc.match(/^##\s*Version:\s*(.+)$/m);
  return (m && m[1].trim()) || "0.0.0";
}

function extractLatestChangelog() {
  const text = fs.readFileSync(path.join(root, "CHANGELOG.md"), "utf8");
  const lines = text.split(/\r?\n/);
  let start = -1;
  for (let i = 0; i < lines.length; i++) {
    if (/^##\s+/.test(lines[i])) {
      start = i;
      break;
    }
  }
  if (start < 0) return text.trim();
  let end = lines.length;
  for (let i = start + 1; i < lines.length; i++) {
    if (/^##\s+/.test(lines[i])) {
      end = i;
      break;
    }
  }
  return lines.slice(start, end).join("\n").trim();
}

async function cfFetch(endpoint, token, apiPath, opts = {}) {
  const res = await fetch(`https://${endpoint}.curseforge.com${apiPath}`, {
    ...opts,
    headers: { ...(opts.headers || {}), "X-Api-Token": token },
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    /* plain */
  }
  return { ok: res.ok, status: res.status, text, json };
}

function buildZip() {
  execFileSync("powershell", ["-NoProfile", "-File", path.join(root, "package.ps1")], {
    cwd: root,
    stdio: "inherit",
  });
  const version = readVersion();
  const zipPath = path.join(root, "dist", `ForeverVendetta-${version}.zip`);
  if (!fs.existsSync(zipPath)) throw new Error(`Missing zip: ${zipPath}`);
  return zipPath;
}

async function main() {
  loadDotEnv();
  const token = process.env.CURSEFORGE_API_TOKEN || process.env.CF_API_TOKEN || process.env.CF_API_KEY;
  if (!token) {
    throw new Error(
      "Set CURSEFORGE_API_TOKEN in .env (https://www.curseforge.com/account/api-tokens)."
    );
  }
  const cfg = loadConfig();
  const endpoint = cfg.endpoint || "wow";
  if (hasFlag("--list-versions")) {
    const { ok, status, json, text } = await cfFetch(endpoint, token, "/api/game/versions");
    if (!ok) throw new Error(`versions failed ${status}: ${text}`);
    const rows = (json || []).filter(
      (v) =>
        String(v.name).startsWith("1.60") ||
        String(v.name).toLowerCase().includes("forever")
    );
    for (const v of rows) console.log(`id=${v.id} name=${v.name}`);
    return;
  }
  if (!cfg.projectId || cfg.projectId === 0) {
    throw new Error("curseforge.json projectId is missing. Create the CurseForge project first.");
  }

  const versions = await cfFetch(endpoint, token, "/api/game/versions");
  if (!versions.ok) throw new Error(`versions failed ${versions.status}: ${versions.text}`);
  const wanted = cfg.gameVersionNames || ["1.60.1"];
  const ids = [];
  for (const name of wanted) {
    const hit = (versions.json || []).find((v) => v.name === name);
    if (!hit) throw new Error(`CurseForge has no game version named ${name}`);
    ids.push(hit.id);
    console.log(`game version ${name} -> id ${hit.id}`);
  }

  const version = readVersion();
  const zipPath = buildZip();
  const changelog = extractLatestChangelog();
  const metadata = {
    changelog,
    changelogType: "markdown",
    displayName: `${cfg.displayNamePrefix || "Forever Vendetta"} ${version}`,
    releaseType: cfg.releaseType || "beta",
    gameVersions: ids,
  };
  console.log(`Uploading ${path.basename(zipPath)} as ${metadata.releaseType} to project ${cfg.projectId}`);
  if (hasFlag("--dry-run")) {
    console.log(JSON.stringify(metadata, null, 2));
    console.log(`dry-run: would upload ${zipPath}`);
    return;
  }

  const form = new FormData();
  form.append("metadata", JSON.stringify(metadata));
  form.append("file", new Blob([fs.readFileSync(zipPath)]), path.basename(zipPath));
  const res = await fetch(
    `https://${endpoint}.curseforge.com/api/projects/${cfg.projectId}/upload-file`,
    { method: "POST", headers: { "X-Api-Token": token }, body: form }
  );
  const text = await res.text();
  if (!res.ok) throw new Error(`upload failed ${res.status}: ${text}`);
  console.log(text || `OK ${res.status}`);
  console.log("Submitted to CurseForge moderation. Watch the project Files tab.");
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
