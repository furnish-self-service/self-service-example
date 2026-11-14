---
name: authoring-dsc-v3
description: Use when writing or reviewing Microsoft DSC v3 configuration documents (*.dsc.yaml) or command-based DSC v3 resources (*.dsc.resource.json plus scripts), including per-OS package differences, _exist/uninstall handling, and resources that fail with schema, exit code or stdout errors. Not for PowerShell DSC v1/v2.
---

# Authoring DSC v3

## Overview

DSC v3 (`dsc` 3.x, Rust) differs from PowerShell DSC and from what most docs and memory suggest. Every rule below was verified against `dsc` 3.3.0. Check unfamiliar behavior with the real CLI before relying on it (see "Verify").

## Configuration documents

- `$schema: https://aka.ms/dsc/schemas/v3/bundled/config/document.json` is **required**.
- **Per-OS differences: put a `condition` on each resource.** Don't gate with `Microsoft.DSC/Assertion` and `dependsOn`: a failed assertion fails the whole run (exit 8) on every OS that doesn't match.

  ```yaml
  resources:
    - name: 7-Zip (winget)
      type: Furnish/Package
      condition: "[equals(context().os.family, 'Windows')]"
      properties: { name: 7zip.7zip }
    - name: 7-Zip
      type: Furnish/Package
      condition: "[not(equals(context().os.family, 'Windows'))]"
      properties: { name: p7zip }
  ```

  `context().os.family` is `Linux`, `macOS` or `Windows`. A skipped resource produces **no result entry at all**, so a run where every resource is skipped returns zero results.
- `dependsOn: ["[resourceId('Type/Name', 'instance name')]"]` pulls the dependency in first. DSC never reverses this order, not even when removing.
- `Microsoft.DSC/Group`, `Assertion`, `Include` and the adapters start the `dsc` executable. Hosts that embed `dsc-lib` (for example furnish) can't use them.

## Command resources

Full working example: [example/](example/), with a manifest, a POSIX sh script and a configuration document.

| Rule | Why |
|---|---|
| stdout is exactly one JSON object, the actual state | DSC parses all of stdout. Send tool output to stderr (`>&2`). |
| `get` returns `"_exist": false` (a boolean) for absent instances, plus the key properties | The synthetic test treats a missing `_exist` as `true` on both sides. The built-in apt resource returns the string `"false"`; don't copy it. |
| `get` exits 0 when the instance is absent | Under `set -e`, a query like `rpm -q` that exits non-zero kills the script. Use `v=$(query) \|\| true`. |
| `get` is side-effect free and cheap | It runs up to 3 times per `set`. |
| Inline `_exist` as `{"type": "boolean"}` | A remote `$ref` in the embedded schema makes the resource unusable: "retrieving it failed". |
| Strict schema: `additionalProperties: false`, `required`, a `pattern` on strings you interpolate | DSC validates input before running the script. Patterns stop JSON and shell injection. |
| `handlesExist: true` on `set` if `set` handles `_exist: false` | Otherwise removal needs a `delete` operation. |
| `implementsPretest: true` and `return: "state"` on `set`, with `set` printing the after-state | Saves two `get` runs. `set` must then be idempotent itself. |
| Without a `test` operation, DSC runs a synthetic test | It compares each desired property with `get` output (case-sensitive). Mark computed properties `readOnly` and don't put them in documents. |
| If you implement `test`, always set `test.return` | When `return` is omitted, v3.3.0 discards test stdout and does `get` plus a diff. |
| Own exit codes are 10 and up, and are mapped in `exitCodes` | For a mapped code, the error message is only the description, and plain stderr text is dropped (`{"error":..}` lines still appear as log output). Tool failures (usually exit 1) must stay unmapped so their stderr reaches the user. |
| Messages on stderr: `{"info":"..."}`, `{"warn":"..."}`, `{"error":"..."}` | The `{"message":..,"level":..}` shape from the docs is not parsed in 3.3.0. |
| `input: env`: properties become env vars (`$name`, `$_exist`); booleans arrive as `"true"`/`"false"` | Absent properties inherit any same-named variable from the parent, so give optional properties defaults. Nested objects (secrets too) can't go through env; use `input: stdin`. |
| `executable` is looked up on PATH first, then in the manifest's directory | Use a unique script name, so a same-named binary on PATH can't win. |
| Type names follow `Owner.Area/Name` | Bump the manifest `version` when the schema changes. |

## Verify

Download `dsc` from https://github.com/PowerShell/DSC/releases, then:

```sh
export DSC_RESOURCE_PATH="$PWD/example"          # dirs containing *.dsc.resource.json
dsc resource get  -r Example.Hosts/Entry -i '{"ip":"10.0.0.5","hostname":"x.example"}'
dsc resource test -r Example.Hosts/Entry -i '{"ip":"10.0.0.5","hostname":"x.example"}'
dsc config test -f example/app.dsc.yaml          # dry run: inDesiredState per resource
dsc config set  -f example/app.dsc.yaml          # apply; run test again → all true
```

To test documents that use furnish's bundled `Furnish/Package`, add furnish's resource directory to `DSC_RESOURCE_PATH`. Run any furnish command once to create it: `~/.local/share/furnish/resources` on Linux, or wherever `FURNISH_DATA_DIR` points.

Before you call a resource done, check four things: `test` on an absent instance is `false`, `set` succeeds, `test` afterwards is `true`, and `set` with `"_exist": false` removes the instance.

## Common mistakes

| Mistake | Symptom |
|---|---|
| OS gating via `Assertion` + `dependsOn` | `Assertion failed`, exit 8, whole configuration fails |
| `$ref` to DSC's canonical property schemas | `Schema: Resource '...exist.json' is not present in a registry` |
| Package-manager chatter on stdout | JSON parse or schema errors after `set` |
| `exitCodes` maps `1` | Every tool failure reads "Invalid arguments", with no details |
| Missing `$schema` in the document | `missing field '$schema'` |
| Treating zero test results as "in desired state" | A Windows-only app looks installed on Linux |
