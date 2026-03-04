# Three Horizons Accelerator — Demo Preparation Checklist

> **Use this checklist 30 minutes before the demo to ensure everything is ready.**

---

## T-30 min: Infrastructure

- [ ] Docker Desktop running with **16 GB RAM** and **6 CPUs** allocated
- [ ] Terminal: `kind get clusters` → shows `three-horizons-demo`
- [ ] Terminal: `kubectl get nodes` → 3 nodes, all `Ready`
- [ ] Terminal: `make -C local validate` → all checks pass

If cluster is not running:
```bash
make -C local up    # Full deploy (~5 min)
```

---

## T-20 min: Services Health

- [ ] `kubectl get pods -A` → zero `CrashLoopBackOff` or `Pending`
- [ ] ArgoCD pods running: `kubectl get pods -n argocd`
- [ ] Monitoring pods running: `kubectl get pods -n observability`
- [ ] Database pods running: `kubectl get pods -n databases`
- [ ] cert-manager: `kubectl get clusterissuer` → shows `selfsigned-issuer`

---

## T-15 min: Port Forwards

Open 5 terminal tabs for port-forwards:

**Tab 1 — ArgoCD:**
```bash
make -C local argocd
# Verify: open https://localhost:8443
```

**Tab 2 — Grafana:**
```bash
make -C local grafana
# Verify: open http://localhost:3000 (admin/admin)
```

**Tab 3 — Prometheus:**
```bash
make -C local prometheus
# Verify: open http://localhost:9090
```

**Tab 4 — Backstage (Open Horizons):**
```bash
kubectl port-forward -n backstage svc/paulasilvatech-backstage 7007:7007
# Verify: open http://localhost:7007 (Blue theme)
```

**Tab 5 — Developer Hub (Three Horizons):**
```bash
kubectl port-forward -n devhub svc/paulasilvatech-devhub-developer-hub 7008:7007
# Verify: open http://localhost:7008 (Red theme)
```

---

## T-10 min: VS Code Setup

- [ ] VS Code open with the accelerator workspace
- [ ] GitHub Copilot Chat extension active (sidebar open)
- [ ] Test agent: type `@deploy hello` → agent responds
- [ ] File explorer open → `.github/agents/` folder visible

### Recommended VS Code Layout
- **Left panel:** File explorer (agents, golden-paths visible)
- **Right panel:** Copilot Chat (full height)
- **Bottom panel:** Integrated terminal (hidden — will open on demand)

---

## T-5 min: Browser Tabs

Open these tabs in order:

1. **ArgoCD** — https://localhost:8443 (login: admin / `make argocd-password`)
2. **Grafana** — http://localhost:3000 (login: admin / admin)
3. **Prometheus** — http://localhost:9090 (Targets page)
4. **Backstage** — http://localhost:7007 (Open Horizons — Blue theme)
5. **Developer Hub** — http://localhost:7008 (Three Horizons — Red theme)

---

## Credentials Quick Reference

| Service | Username | Password |
|---------|----------|----------|
| ArgoCD | admin | Run: `make -C local argocd-password` |
| Grafana | admin | admin |
| PostgreSQL | postgres | demo-postgres-2026 |
| Redis | — | demo-redis-2026 |
| Backstage | guest | (no password) |
| Developer Hub | guest | (no password) |

---

## Quick Recovery Commands

| Problem | Fix |
|---------|-----|
| Port-forward died | Re-run `make argocd`, `make grafana`, etc. |
| Pod crashing | `kubectl delete pod <pod> -n <ns>` (auto-recreates) |
| All broken | `make -C local reset` (full rebuild ~5 min) |
| Agent not responding | Reload VS Code (`Cmd+Shift+P` → Reload Window) |
| Grafana no data | Wait 2 min for Prometheus scrape interval |

---

## Final Check

- [ ] All 5 browser tabs loading (ArgoCD, Grafana, Prometheus, Backstage, DevHub)
- [ ] VS Code Copilot Chat responding to `@deploy`
- [ ] At least 1 Grafana dashboard showing data
- [ ] Backstage shows Blue theme at localhost:7007
- [ ] Developer Hub shows Red theme + MS/GitHub logos at localhost:7008
- [ ] Presenter display/projector connected
- [ ] Notifications silenced (Do Not Disturb mode)

---

## GitHub App for Developer Hub

The Developer Hub requires its own GitHub App (separate from Backstage).

### Create the GitHub App

1. Go to https://github.com/settings/apps/new
2. Fill in:
   - **Name:** `three-horizons-devhub`
   - **Homepage URL:** `http://localhost:7008`
   - **Callback URL:** `http://localhost:7008/api/auth/github/handler/frame`
   - **Webhook:** Uncheck "Active" (not needed for local)
3. Permissions:
   - **Repository:** Contents (Read), Metadata (Read), Pull Requests (Read & Write), Issues (Read & Write), Actions (Read)
   - **Organization:** Members (Read)
4. Click "Create GitHub App"
5. Note the **App ID** and **Client ID**
6. Generate a **Client Secret** — copy it
7. Generate a **Private Key** — download the `.pem` file

### Create the Kubernetes Secret

```bash
kubectl -n devhub delete secret paulasilvatech-devhub-github-app 2>/dev/null
kubectl -n devhub create secret generic paulasilvatech-devhub-github-app \
  --from-literal=app-id='YOUR_APP_ID' \
  --from-literal=client-id='YOUR_CLIENT_ID' \
  --from-literal=client-secret='YOUR_CLIENT_SECRET' \
  --from-file=private-key=/path/to/private-key.pem \
  --from-literal=webhook-secret='optional-webhook-secret'
```

### Redeploy

```bash
helm upgrade --install paulasilvatech-devhub \
  backstage/backstage \
  -n devhub -f local/values/backstage-local.yaml --wait=false
```

Wait for pod to be 1/1 Running, then port-forward on 7008.

**Ready for demo!** Open `local/DEMO_SCRIPT.md` for the walkthrough.
