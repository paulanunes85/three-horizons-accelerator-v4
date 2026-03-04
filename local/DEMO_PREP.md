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

Open 3 terminal tabs for port-forwards:

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
4. **RHDH** — http://localhost:7007 (if enabled)

---

## Credentials Quick Reference

| Service | Username | Password |
|---------|----------|----------|
| ArgoCD | admin | Run: `make -C local argocd-password` |
| Grafana | admin | admin |
| PostgreSQL | postgres | demo-postgres-2026 |
| Redis | — | demo-redis-2026 |
| RHDH | guest | (no password) |

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

- [ ] All 4 browser tabs loading
- [ ] VS Code Copilot Chat responding to `@deploy`
- [ ] At least 1 Grafana dashboard showing data
- [ ] Presenter display/projector connected
- [ ] Notifications silenced (Do Not Disturb mode)

**Ready for demo!** Open `local/DEMO_SCRIPT.md` for the walkthrough.
