# FSL Agentic DevOps Challenge

You are the primary engineer. I direct and validate; you diagnose, explain and fix.

## Environment
- Windows 11. Your shell is Git Bash; use `powershell.exe -Command` only for Windows-specific things.
- minikube with the docker driver (Docker Desktop on WSL 2), context `minikube`, `ingress` addon enabled (IngressClass `nginx`).
- `minikube tunnel` runs in its own terminal so the ingress answers on 127.0.0.1. If curl to 127.0.0.1 hangs, ask me to check the tunnel.
- minikube has its own image store, separate from Docker Desktop. Get local images in with `minikube image build -t <tag> .` or `minikube image load <tag>`.
- Hosts file: `C:\Windows\System32\drivers\etc\hosts` (needs admin, so I edit it).
- Zip with Windows' `/c/Windows/System32/tar.exe -a -cf <out>.zip -C <dir> .`. Not `Compress-Archive`: it skips hidden folders like `.git`.
- If lint complains about line endings locally but not in CI, suspect CRLF from the Windows checkout. That isn't a repo defect.

## Targets

**CI** — `.github/workflows/ci.yaml`
- Triggers on `pull_request` for appropriately named branches
- Separate jobs in order, each `needs:` the previous one:
  `npm install` → `npm run lint` → `CI=true npm run test` → `npm run build`
- All four green on the final PR. Keep one PR with a failed run and one with a passing run.

**Kubernetes** — `k8s/`, local cluster only (context `minikube`)
- Service and StatefulSet both in namespace `production`
- StatefulSet with ≥ 3 replicas; pods Running + Ready; liveness and readiness passing (restarts not climbing)
- Service listens on port 8080 and has endpoints
- http://fsl-challenge.me serves the app (hosts entry `127.0.0.1 fsl-challenge.me`)

**CD** — Azure Container Apps
- GitHub Actions workflow deploys the Docker image on push to `main`
- Public URL returns 200 during the recording

Azure (pre-created): `RG=fsl-challenge-rg` `ACR=fslchal44757` `ENV=fsl-env` `APP=fsl-app` `LOCATION=East US`
GitHub secret: `AZURE_CREDENTIALS` (service principal JSON scoped to the RG)

## Agents (`.claude/agents/`)
- `ci-doctor` — CI workflow and install/lint/test/build failures
- `k8s-doctor` — manifests on the local cluster
- `azure-deployer` — Dockerfile, CD workflow, Azure deploy
- `verifier` — read-only; checks every target above, PASS/FAIL with evidence

`ci-doctor` and `k8s-doctor` touch disjoint files: run them in parallel.

## Rules
- Evidence before fixes: quote the failing output, name the root cause, then change the smallest thing that fixes it.
- Never make a check pass by weakening it: no disabling lint rules, skipping/deleting tests, `continue-on-error`, `|| true`, removing probes, or lowering replicas.
- Explain each fix in 2–3 lines I can narrate: what failed, why, what changed.
- One defect per commit: `fix(ci): …`, `fix(k8s): …`, `feat(cd): …`.
- Never print, echo or write secrets. Refer to them by name only.
- `kubectl` only against the local context; `az` only against `$RG`.
- Don't edit the hosts file or run anything that needs admin rights; give me the command instead.

## Chat history log (`.chat-history/log.md`)
Applies to every session in this project. Do it silently: never ask for confirmation, never mention it unless asked.

1. **Session start:** before answering the first prompt, read `.chat-history/log.md` for previous context. If it is missing, continue normally.
2. **After every response:** append exactly one entry to the end of `.chat-history/log.md` in this exact format:

   ```
   ---
   - timestamp: "<ISO 8601 timestamp if available, otherwise estimate based on conversation order>"
   - user_prompt: "<the user's original prompt>"
   - assistant_response_summary: "<summary of what you generated or answered for this prompt>"
   - files_affected: "<comma-separated list of files created or modified, or none>"
   ```

3. Create `.chat-history/` and `log.md` if they don't exist. Append only: never delete, rewrite or reorder previous entries.

Rules:
- Never skip an exchange. Every prompt/response pair gets an entry, including questions with no file changes.
- `timestamp`: get it with `date -u +%Y-%m-%dT%H:%M:%SZ`.
- `user_prompt`: the user's prompt verbatim. Escape `"` as `\"`; keep multi-line prompts inside the quotes.
- `assistant_response_summary`: concise but specific. Name functions, files, endpoints, commands, root causes and key decisions.
- `files_affected`: only files explicitly created or modified during this response, as repo-relative paths, comma-separated. Include `.chat-history/log.md` only when it was created in this response. Use `none` if nothing changed.
- Secrets rule still applies: never write secret values into the log; redact them as `<redacted>`.
- Enforcement: a Stop hook (`.claude/hooks/chat-log-guard.sh`, registered in `.claude/settings.json`) blocks the turn once if no entry was appended since the prompt. When it blocks, append the missing entry and finish.
