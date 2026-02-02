import { useState } from "react";

const C = {
  azure: "#0078D4", azDk: "#003B73", gh: "#24292F", rh: "#EE0000",
  gcp: "#4285F4", aws: "#FF9900", onp: "#5C2D91", arc: "#50E6FF",
  grn: "#107C10", bg: "#F3F6FC", brd: "#D2D6DC", txt: "#1B1B1B",
  mut: "#6B7280", pink: "#E83E8C",
};

const f = "'Segoe UI', system-ui, sans-serif";

const B = ({ children, bg = C.azure, c = "#fff", bd, s = {} }) => (
  <span style={{ display: "inline-flex", alignItems: "center", gap: 4, padding: "3px 10px", borderRadius: 4, fontSize: 10, fontWeight: 700, background: bg, color: c, letterSpacing: "0.04em", border: bd ? `1.5px solid ${bd}` : "none", lineHeight: 1.4, whiteSpace: "nowrap", fontFamily: f, ...s }}>{children}</span>
);

const SH = ({ icon, title, sub, color = C.azure }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 14px", background: `linear-gradient(135deg, ${color}, ${color}dd)`, borderRadius: "8px 8px 0 0", color: "#fff" }}>
    <span style={{ fontSize: 18 }}>{icon}</span>
    <div>
      <div style={{ fontWeight: 700, fontSize: 13, letterSpacing: "0.03em", fontFamily: f }}>{title}</div>
      {sub && <div style={{ fontSize: 10, opacity: 0.85, fontWeight: 400 }}>{sub}</div>}
    </div>
  </div>
);

const CC = ({ title, items, ac = C.azure, icon, opt }) => (
  <div style={{ background: "#fff", border: `1px solid ${ac}20`, borderRadius: 6, padding: "8px 10px", borderLeft: `3px solid ${ac}`, flex: 1, minWidth: 130, position: "relative" }}>
    {opt && <span style={{ position: "absolute", top: -6, right: 6, fontSize: 8, background: "#FFF3CD", color: "#856404", padding: "1px 6px", borderRadius: 3, fontWeight: 700 }}>OPTIONAL</span>}
    <div style={{ fontSize: 10, fontWeight: 700, color: ac, marginBottom: 4, display: "flex", alignItems: "center", gap: 4, textTransform: "uppercase", letterSpacing: "0.06em", fontFamily: f }}>
      {icon && <span style={{ fontSize: 12 }}>{icon}</span>}{title}
    </div>
    {items.map((it, i) => (
      <div key={i} style={{ fontSize: 10, color: C.txt, padding: "2px 0", display: "flex", alignItems: "center", gap: 4, fontFamily: f }}>
        <span style={{ color: ac, fontSize: 8 }}>●</span> {it}
      </div>
    ))}
  </div>
);

const Ar = ({ label }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2, padding: "4px 0" }}>
    <div style={{ width: 2, height: 12, background: C.azure }} />
    <span style={{ fontSize: 8, color: C.mut, fontStyle: "italic", fontFamily: f }}>{label}</span>
    <span style={{ color: C.azure, fontSize: 10 }}>▼</span>
  </div>
);

const PS = ({ children, s = {} }) => (
  <div style={{ background: "#fff", border: `1px solid ${C.brd}`, borderRadius: 8, overflow: "hidden", ...s }}>{children}</div>
);

const CRP = ({ cloud, icon, color, items, opt }) => (
  <div style={{ background: "#fff", border: `1.5px solid ${color}30`, borderRadius: 8, flex: 1, minWidth: 165, opacity: opt ? 0.88 : 1, position: "relative", boxShadow: `0 2px 8px ${color}10` }}>
    {opt && <span style={{ position: "absolute", top: -8, right: 8, fontSize: 8, background: "#FFF3CD", color: "#856404", padding: "1px 8px", borderRadius: 4, fontWeight: 700, border: "1px solid #856404", zIndex: 2 }}>OPTIONAL</span>}
    <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "8px 10px", background: `linear-gradient(135deg, ${color}12, ${color}06)`, borderBottom: `1.5px solid ${color}20`, borderRadius: "8px 8px 0 0" }}>
      <span style={{ fontSize: 16 }}>{icon}</span>
      <span style={{ fontSize: 12, fontWeight: 700, color, fontFamily: f }}>{cloud}</span>
    </div>
    <div style={{ padding: "6px 10px", display: "flex", flexDirection: "column", gap: 3 }}>
      {items.map(({ l, s: sv, sub }, i) => (
        <div key={i} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "3px 6px", background: `${color}06`, borderRadius: 4, border: `1px solid ${color}10` }}>
          <span style={{ fontSize: 9, color: C.mut, fontWeight: 600, fontFamily: f }}>{l}</span>
          <div style={{ textAlign: "right" }}>
            <span style={{ fontSize: 9, color: C.txt, fontWeight: 600, fontFamily: f }}>{sv}</span>
            {sub && <div style={{ fontSize: 8, color: C.mut }}>{sub}</div>}
          </div>
        </div>
      ))}
    </div>
  </div>
);

const Per = ({ icon, label, color = C.azure }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 2, padding: "6px 8px" }}>
    <span style={{ fontSize: 22 }}>{icon}</span>
    <span style={{ fontSize: 9, fontWeight: 700, color, textAlign: "center", textTransform: "uppercase", letterSpacing: "0.05em", fontFamily: f, whiteSpace: "pre-line" }}>{label}</span>
  </div>
);

const Personas = () => (
  <div style={{ display: "flex", justifyContent: "space-around", padding: "0 40px" }}>
    <Per icon="👩‍💻" label={"Developers"} color={C.gh} />
    <Per icon="🏗️" label={"Platform\nEngineers"} color={C.azure} />
    <Per icon="🎨" label={"DevEx\nEngineers"} color={C.rh} />
    <Per icon="☁️" label={"Cloud\nEngineers"} color={C.azDk} />
  </div>
);

const DevCtrlPlane = ({ multi }) => (
  <PS>
    <SH icon="🎛️" title="Developer Control Plane" sub="Service Catalog · API Catalog · Developer Portal" color={C.rh} />
    <div style={{ padding: 10, display: "flex", gap: 8, flexWrap: "wrap" }}>
      <CC title="Developer Hub" icon="🎩" ac={C.rh} items={["Red Hat Developer Hub", multi ? "Multi-Cluster Templates" : "Software Templates", `Golden Paths (${multi ? "21+" : "21"})`, multi ? "Environment Selector" : "Tech Docs & API Catalog"]} />
      <CC title="Version Control" icon="🐙" ac={C.gh} items={["GitHub Enterprise Cloud", multi ? "App + Platform Source Code" : "Application Source Code", multi ? "Multi-Env Branch Strategy" : "Platform Source Code (Terraform)", `Copilot Agents (${multi ? "23" : "23"})`]} />
      <CC title="Dev Environments" icon="💻" ac={C.azure} items={["GitHub Codespaces", "Microsoft DevBox", "VS Code + Copilot Enterprise", "spec-kit Methodology"]} />
    </div>
  </PS>
);

const CIPlane = ({ multi }) => (
  <PS>
    <SH icon="🔄" title="Integration & Delivery Plane" sub={multi ? "CI · Registry · Platform Orchestrator · Multi-Target CD" : "CI Pipeline · Registry · CD Pipeline · GitOps"} color={C.gh} />
    <div style={{ padding: 10, display: "flex", gap: 8, flexWrap: "wrap" }}>
      <CC title="CI Pipeline" icon="⚡" ac={C.gh} items={["GitHub Actions", multi ? "GHAS + Defender Unified" : "GHAS Code Scanning", multi ? "Multi-Arch Builds" : "Secret Scanning", multi ? "Azure Pipelines (hybrid)" : "Dependency Review"]} />
      <CC title="Registry" icon="📦" ac={C.azure} items={["Azure Container Registry", multi ? "Geo-Replication" : "Helm Chart Repository", multi ? "Helm Charts (OCI)" : "OCI Artifacts", multi ? "SBOM & Signatures" : "Image Signing (Notation)"]} />
      <CC title="Platform Orchestrator" icon="🔷" ac={multi ? "#FF6D00" : C.azure} items={[multi ? "ArgoCD Multi-Cluster" : "ArgoCD GitOps", multi ? "ApplicationSets (Generators)" : "ApplicationSets", "Target State Repo", multi ? "Red Hat Ansible Automation" : "Progressive Delivery"]} />
      <CC title="Security" icon="🛡️" ac={C.grn} items={["GHAS + Defender for Cloud", "Unified Code-to-Cloud", multi ? "Azure Policy (Arc-extended)" : "Workload Identity", multi ? "Defender Multi-Cloud" : "Key Vault + ExternalSecrets"]} />
    </div>
  </PS>
);

const MonPlane = ({ multi }) => (
  <PS>
    <SH icon="📊" title="Monitoring & Logging Plane" sub={multi ? "Unified Observability across all Resource Planes" : "Observability · Alerting · Dashboards"} color={C.pink} />
    <div style={{ padding: 10, display: "flex", gap: 8, flexWrap: "wrap" }}>
      <CC title="Metrics" icon="📈" ac={C.pink} items={[multi ? "Prometheus (per cluster)" : "Prometheus", multi ? "Azure Monitor (Arc)" : "Azure Monitor", multi ? "Federation / Thanos" : "Custom Metrics"]} />
      <CC title="Visualization" icon="📊" ac={C.pink} items={[multi ? "Grafana (Multi-Cluster)" : "Grafana Dashboards (4)", "Azure Dashboards", multi ? "Cost per Cloud" : "Cost Dashboards"]} />
      <CC title="Logging" icon="📝" ac={C.pink} items={[multi ? "Loki / Log Analytics" : "Loki / Azure Log Analytics", multi ? "Cross-Cloud Audit Logs" : "Audit Logs", "SIEM Integration"]} />
      <CC title="Alerting" icon="🔔" ac={C.pink} items={[multi ? "AlertManager (unified)" : "AlertManager Rules", "PagerDuty / OpsGenie", multi ? "SLA/SLO per Cluster" : "SLA/SLO Monitoring"]} />
    </div>
  </PS>
);

const AzureOnly = () => (
  <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
    <Personas />
    <DevCtrlPlane />
    <Ar label="CI/CD Trigger" />
    <CIPlane />
    <Ar label="Deploy to Azure" />
    <PS>
      <SH icon="☁️" title="Azure Resource Plane" sub="Primary Compute · Data · Networking · Services" color={C.azure} />
      <div style={{ padding: 10, display: "flex", gap: 8, flexWrap: "wrap" }}>
        <CRP cloud="Azure (Primary)" icon="☁️" color={C.azure} items={[
          { l: "Compute", s: "AKS or ARO", sub: "User selects via variable" },
          { l: "Data", s: "Azure SQL / CosmosDB" },
          { l: "Networking", s: "VNet · NSG · Private EP" },
          { l: "Services", s: "Service Bus · Event Hub" },
          { l: "AI", s: "Azure AI Foundry" },
          { l: "Governance", s: "Purview · Defender" },
        ]} />
        <div style={{ flex: 0.8, display: "flex", flexDirection: "column", gap: 4, padding: 8, background: `${C.azure}06`, borderRadius: 8, border: `1px dashed ${C.azure}30` }}>
          <div style={{ fontSize: 10, fontWeight: 700, color: C.azure, fontFamily: f, textAlign: "center" }}>🏗️ Terraform Modules (16)</div>
          {["aks-cluster / aro", "networking", "security (Key Vault)", "container-registry", "argocd", "rhdh", "observability", "defender", "databases", "ai-foundry", "external-secrets", "github-runners", "naming", "cost-management", "purview", "disaster-recovery"].map((m, i) => (
            <div key={i} style={{ fontSize: 8, color: C.txt, padding: "2px 6px", background: i % 2 === 0 ? `${C.azure}08` : "transparent", borderRadius: 3, fontFamily: "'Cascadia Code', monospace" }}>
              terraform/modules/{m}
            </div>
          ))}
        </div>
      </div>
    </PS>
    <Ar label="Metrics & Logs" />
    <MonPlane />
  </div>
);

const MultiCloud = () => (
  <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
    <Personas />
    <DevCtrlPlane multi />
    <Ar label="CI/CD Trigger" />
    <CIPlane multi />
    <Ar label="Deploy via ArgoCD + Azure Arc" />
    <div style={{ border: `2px solid ${C.arc}60`, borderRadius: 10, padding: 0, background: `${C.arc}04`, position: "relative" }}>
      <div style={{ position: "absolute", top: -10, left: 20, background: C.arc, color: "#000", padding: "2px 12px", borderRadius: 4, fontSize: 10, fontWeight: 700, fontFamily: f, letterSpacing: "0.05em" }}>
        🌐 AZURE ARC — UNIFIED CONTROL PLANE
      </div>
      <div style={{ padding: "16px 10px 10px", display: "flex", flexDirection: "column", gap: 10 }}>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <CRP cloud="On-Premises / Private" icon="🏢" color={C.onp} opt items={[
            { l: "Compute", s: "OpenShift (OCP)" },
            { l: "K8s", s: "Kubernetes (CNCF)" },
            { l: "Virtualization", s: "VMware / HCI" },
            { l: "Automation", s: "Red Hat Ansible" },
            { l: "APIs", s: "Infra + Security" },
          ]} />
          <CRP cloud="Azure (Primary)" icon="☁️" color={C.azure} items={[
            { l: "Compute", s: "AKS or ARO" },
            { l: "Data", s: "Azure SQL / CosmosDB" },
            { l: "Networking", s: "VNet · DNS · Private EP" },
            { l: "Services", s: "Service Bus · AI Foundry" },
            { l: "Governance", s: "Defender + Purview" },
          ]} />
        </div>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <CRP cloud="Google Cloud" icon="🔵" color={C.gcp} opt items={[
            { l: "Compute", s: "GKE (Arc-connected)" },
            { l: "Data", s: "Cloud SQL" },
            { l: "Networking", s: "Cloud DNS" },
            { l: "Services", s: "Pub/Sub" },
          ]} />
          <CRP cloud="Amazon Web Services" icon="🟠" color={C.aws} opt items={[
            { l: "Compute", s: "EKS (Arc-connected)" },
            { l: "Data", s: "RDS / Aurora" },
            { l: "Networking", s: "Route 53" },
            { l: "Services", s: "SQS / SNS" },
          ]} />
        </div>
        <div style={{ display: "flex", gap: 6, justifyContent: "center", flexWrap: "wrap", padding: "6px 0 2px" }}>
          {["Azure Policy (Arc)", "Defender Multi-Cloud", "Azure Monitor (Arc)", "GitOps (Flux/ArgoCD)", "Workload Identity", "Azure RBAC (Arc)"].map((x, i) => (
            <B key={i} bg={`${C.arc}20`} c={C.azDk} bd={C.arc}>{x}</B>
          ))}
        </div>
      </div>
    </div>
    <Ar label="Unified Metrics & Logs (all clusters)" />
    <MonPlane multi />
  </div>
);

export default function App() {
  const [sc, setSc] = useState("azure");
  const [leg, setLeg] = useState(false);
  return (
    <div style={{ fontFamily: f, background: C.bg, minHeight: "100vh" }}>
      <div style={{ background: "linear-gradient(135deg, #0078D4 0%, #003B73 50%, #24292F 100%)", padding: "20px 24px 16px", color: "#fff" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", flexWrap: "wrap", gap: 12 }}>
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
              <span style={{ fontSize: 10, background: "#ffffff20", padding: "2px 8px", borderRadius: 3, fontWeight: 600, letterSpacing: "0.08em" }}>REFERENCE ARCHITECTURE</span>
              <span style={{ fontSize: 10, background: "#50E6FF30", color: "#50E6FF", padding: "2px 8px", borderRadius: 3, fontWeight: 600 }}>v4.0</span>
            </div>
            <h1 style={{ fontSize: 22, fontWeight: 800, margin: 0, lineHeight: 1.2, letterSpacing: "-0.01em" }}>Three Horizons Platform Engineering</h1>
            <div style={{ fontSize: 11, opacity: 0.8, marginTop: 4 }}>GitHub · Microsoft Azure · Red Hat — Enterprise Platform Engineering Accelerator</div>
          </div>
          <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
            <B bg="#ffffff20" c="#fff" bd="#ffffff40">GitHub Enterprise</B>
            <B bg="#ffffff20" c="#fff" bd="#ffffff40">Azure</B>
            <B bg="#ffffff20" c="#fff" bd="#ffffff40">Red Hat</B>
            <B bg="#ffffff20" c="#fff" bd="#ffffff40">Terraform</B>
          </div>
        </div>
      </div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, padding: "14px 16px", background: "#fff", borderBottom: `1px solid ${C.brd}`, flexWrap: "wrap" }}>
        <span style={{ fontSize: 11, fontWeight: 600, color: C.mut, letterSpacing: "0.05em" }}>DEPLOYMENT SCENARIO:</span>
        {[["azure", "☁️ Scenario A: Azure-Only", C.azure], ["hybrid", "🌐 Scenario B: Multi-Cloud Hybrid", C.onp]].map(([k, label, col]) => (
          <button key={k} onClick={() => setSc(k)} style={{ padding: "8px 20px", borderRadius: 6, border: "none", cursor: "pointer", fontWeight: 700, fontSize: 12, fontFamily: f, background: sc === k ? col : "#E8ECF0", color: sc === k ? "#fff" : C.mut, transition: "all 0.2s", boxShadow: sc === k ? `0 2px 8px ${col}40` : "none" }}>{label}</button>
        ))}
        <button onClick={() => setLeg(!leg)} style={{ padding: "8px 14px", borderRadius: 6, border: `1px solid ${C.brd}`, cursor: "pointer", fontWeight: 600, fontSize: 11, fontFamily: f, background: leg ? "#F0F0F0" : "#fff", color: C.mut }}>{leg ? "✕ Hide" : "ℹ️ Legend"}</button>
      </div>
      <div style={{ padding: "10px 20px", background: sc === "azure" ? `${C.azure}08` : `${C.onp}08`, borderBottom: `1px solid ${C.brd}` }}>
        <div style={{ fontSize: 11, color: C.txt, maxWidth: 900, fontFamily: f, lineHeight: 1.6 }}>
          {sc === "azure" ? (
            <><strong style={{ color: C.azure }}>Scenario A — Azure-Only:</strong> All workloads deployed on Azure using AKS or ARO (user selects via Terraform variable). <strong>Recommended starting point</strong> for most organizations. Developer Hub runs on the chosen cluster, GitHub Actions handles CI, ArgoCD manages GitOps CD. All 16 Terraform modules deploy Azure-native resources.</>
          ) : (
            <><strong style={{ color: C.onp }}>Scenario B — Multi-Cloud Hybrid:</strong> Primary deployment on Azure with <strong>Azure Arc as unified control plane</strong> extending management to on-premises (OpenShift/K8s), Google Cloud (GKE), and/or AWS (EKS). ArgoCD uses ApplicationSets with cluster generators for multi-target deployment. Azure Policy, Defender, and Monitor extend to all Arc-connected clusters. <em style={{ color: C.mut }}>On-prem, GCP, AWS targets are optional — enable via Terraform variables.</em></>
          )}
        </div>
      </div>
      {leg && (
        <div style={{ padding: "12px 20px", background: "#FFFDE7", borderBottom: "1px solid #FFF59D", display: "flex", gap: 12, flexWrap: "wrap", alignItems: "center" }}>
          <span style={{ fontSize: 10, fontWeight: 700, color: "#5D4037" }}>LEGEND:</span>
          {[[C.rh, "Red Hat"], [C.gh, "GitHub"], [C.azure, "Azure"], [C.grn, "Security"], [C.onp, "On-Premises"], [C.gcp, "Google Cloud"], [C.aws, "AWS"]].map(([bg, lb], i) => <B key={i} bg={bg}>{lb}</B>)}
          <B bg={C.arc} c="#000">Azure Arc</B>
          <B bg="#FFF3CD" c="#856404" bd="#856404">Optional</B>
        </div>
      )}
      <div style={{ padding: "16px 16px 20px", maxWidth: 960, margin: "0 auto" }}>
        {sc === "azure" ? <AzureOnly /> : <MultiCloud />}
      </div>
      <div style={{ padding: "12px 20px 8px", maxWidth: 960, margin: "0 auto" }}>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          {[
            { h: "H1", t: "Foundation", c: C.azure, i: ["AKS/ARO", "VNet/NSG", "Key Vault", "ACR", "Identities", "GitOps Base"] },
            { h: "H2", t: "Enhancement", c: C.grn, i: ["Developer Hub", "Golden Paths", "GHAS+Defender", "Observability", "Codespaces/DevBox", sc === "hybrid" ? "Azure Arc" : "ADO Hybrid"] },
            { h: "H3", t: "Innovation", c: C.pink, i: ["Copilot Enterprise", "Agent Mode", "Coding Agent", "spec-kit", "MCP Servers", "Agentic DevOps"] },
          ].map(({ h, t, c, i: items }) => (
            <div key={h} style={{ flex: 1, minWidth: 200, background: "#fff", border: `1px solid ${c}30`, borderRadius: 8, overflow: "hidden" }}>
              <div style={{ background: `linear-gradient(135deg, ${c}, ${c}cc)`, padding: "6px 12px", color: "#fff", display: "flex", alignItems: "center", gap: 6 }}>
                <span style={{ fontSize: 14, fontWeight: 800 }}>{h}</span>
                <span style={{ fontSize: 11, fontWeight: 600 }}>{t}</span>
              </div>
              <div style={{ padding: "8px 12px", display: "flex", flexWrap: "wrap", gap: 4 }}>
                {items.map((it, j) => <B key={j} bg={`${c}12`} c={c} s={{ fontSize: 9 }}>{it}</B>)}
              </div>
            </div>
          ))}
        </div>
      </div>
      <div style={{ textAlign: "center", padding: "12px 16px 20px", fontSize: 9, color: C.mut }}>
        Three Horizons Platform Engineering Accelerator — Reference Architecture v4.0 | GitHub · Microsoft · Red Hat
      </div>
    </div>
  );
}
