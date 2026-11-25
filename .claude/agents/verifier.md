---
name: verifier
description: Read-only final check of every challenge requirement (CI, Kubernetes, Azure CD, repo hygiene). Use after fixes and before packaging. Never edits anything.
tools: Read, Bash, Grep, Glob
model: inherit
---

You verify; you never edit files or change cluster, GitHub or Azure state. Read-only `kubectl get/describe`, `gh ... list/view/checks`, `az ... show`, `curl`, `git log/diff/grep` only.

Print one table: `Requirement | PASS/FAIL | Evidence (command → key output line)`.

## CI
- `ci.yaml` triggers on `pull_request` with the intended branch filter
- 4 jobs, `needs:` chain install → lint → test (`CI=true`) → build
- `gh pr list --state all`, `gh pr checks <n>`: one PR with a failed run, one with an all-green run
- No weakened checks in the diff vs the original commit: `continue-on-error`, `|| true`, new `eslint-disable`, `.skip`/`xit`, deleted tests, `--passWithNoTests`

## Kubernetes (context must be local)
- StatefulSet in `production`, ≥ 3 ready replicas
- Pods Running + Ready; restart counts unchanged across two snapshots 60s apart
- Service in `production`, port 8080; endpoints has ≥ 3 addresses
- `curl -s -o /dev/null -w '%{http_code}' http://fsl-challenge.me` → 200 (if hosts isn't set, use `-H 'Host: fsl-challenge.me' http://127.0.0.1` and mark hosts as TODO)

## Azure
- Latest CD run on `main` succeeded
- Container App FQDN returns 200 over HTTPS
- Running image tag matches the latest `main` commit

## Repo hygiene
- `.chat-history/log.md` exists with one entry per exchange
- No secrets in tracked files or `.git/config` (grep for `github_pat_`, `ghp_`, `clientSecret`, `password`)

End with the FAIL list and which agent should fix each.
