import { Content, Header, Page, InfoCard, StatusOK, StatusWarning } from '@backstage/core-components';
import { Grid, makeStyles, Typography, Box, Chip, Table, TableBody, TableCell, TableHead, TableRow } from '@material-ui/core';
import CloudIcon from '@material-ui/icons/Cloud';
import StorageIcon from '@material-ui/icons/Storage';
import SpeedIcon from '@material-ui/icons/Speed';

const useStyles = makeStyles(theme => ({
  statusBanner: {
    background: 'linear-gradient(135deg, #2e7d32 0%, #00B7C3 100%)',
    borderRadius: 12, padding: theme.spacing(3, 4), color: '#fff',
    display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: theme.spacing(3),
  },
  metricBox: { textAlign: 'center' as const, padding: theme.spacing(2) },
  metricValue: { fontSize: '2rem', fontWeight: 700, color: '#0078D4' },
}));

const services = [
  { name: 'Backstage Portal', ns: 'rhdh', status: 'healthy', ver: 'v1.48.0', rep: '2/2' },
  { name: 'ArgoCD', ns: 'argocd', status: 'healthy', ver: 'v2.13.0', rep: '3/3' },
  { name: 'Prometheus', ns: 'monitoring', status: 'healthy', ver: 'v2.51.0', rep: '2/2' },
  { name: 'Grafana', ns: 'monitoring', status: 'healthy', ver: 'v10.4.0', rep: '1/1' },
  { name: 'PostgreSQL', ns: 'databases', status: 'healthy', ver: '16.2', rep: '1/1' },
  { name: 'Ingress NGINX', ns: 'ingress', status: 'healthy', ver: 'v1.10.0', rep: '2/2' },
  { name: 'Cert Manager', ns: 'cert-manager', status: 'healthy', ver: 'v1.14.0', rep: '1/1' },
  { name: 'External Secrets', ns: 'external-secrets', status: 'warning', ver: 'v0.9.0', rep: '1/1' },
];

const argoApps = [
  { name: 'three-horizons-portal', sync: 'Synced', health: 'Healthy' },
  { name: 'monitoring-stack', sync: 'Synced', health: 'Healthy' },
  { name: 'argocd', sync: 'Synced', health: 'Healthy' },
  { name: 'gatekeeper', sync: 'Synced', health: 'Healthy' },
  { name: 'external-secrets', sync: 'OutOfSync', health: 'Degraded' },
];

const envs = [
  { name: 'Development', cluster: 'aks-dev-centralus', region: 'Central US', nodes: 3, pods: 42 },
  { name: 'Staging', cluster: 'aks-stg-eastus', region: 'East US', nodes: 3, pods: 38 },
  { name: 'Production', cluster: 'aks-prod-centralus', region: 'Central US', nodes: 5, pods: 67 },
];

const StatusIcon = ({ s }: { s: string }) => {
  if (s === 'healthy' || s === 'Healthy' || s === 'Synced') return <StatusOK />;
  return <StatusWarning />;
};

const PlatformStatusPage = () => {
  const classes = useStyles();
  const ok = services.filter(s => s.status === 'healthy').length;
  return (
    <Page themeId="tool">
      <Header title="Platform Status" subtitle="Real-time health and status of the Agentic DevOps Platform" />
      <Content>
        <div className={classes.statusBanner}>
          <div>
            <Typography variant="h5" style={{ fontWeight: 700 }}>All Systems Operational</Typography>
            <Typography variant="body2" style={{ opacity: 0.9, marginTop: 4 }}>{ok}/{services.length} services healthy</Typography>
          </div>
          <CloudIcon style={{ fontSize: 48, opacity: 0.5 }} />
        </div>
        <Grid container spacing={3}>
          {[{ v: '22', l: 'Golden Paths' }, { v: String(services.length), l: 'Platform Services' }, { v: '3', l: 'Environments' }, { v: '99.9%', l: 'Uptime (30d)' }].map(m => (
            <Grid item xs={6} sm={3} key={m.l}>
              <Box className={classes.metricBox}>
                <Typography className={classes.metricValue}>{m.v}</Typography>
                <Typography variant="body2" color="textSecondary">{m.l}</Typography>
              </Box>
            </Grid>
          ))}
        </Grid>
        <Box mt={3}>
          <Grid container spacing={3}>
            <Grid item xs={12} md={7}>
              <InfoCard title="Platform Services" subheader="Service health across namespaces">
                <Table size="small">
                  <TableHead><TableRow><TableCell>Service</TableCell><TableCell>Namespace</TableCell><TableCell>Status</TableCell><TableCell>Version</TableCell><TableCell>Replicas</TableCell></TableRow></TableHead>
                  <TableBody>
                    {services.map(s => (
                      <TableRow key={s.name}>
                        <TableCell style={{ fontWeight: 500 }}>{s.name}</TableCell>
                        <TableCell><Chip size="small" label={s.ns} variant="outlined" /></TableCell>
                        <TableCell><StatusIcon s={s.status} /> {s.status}</TableCell>
                        <TableCell>{s.ver}</TableCell>
                        <TableCell>{s.rep}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </InfoCard>
            </Grid>
            <Grid item xs={12} md={5}>
              <InfoCard title="ArgoCD Applications" subheader="GitOps sync status">
                <Table size="small">
                  <TableHead><TableRow><TableCell>Application</TableCell><TableCell>Sync</TableCell><TableCell>Health</TableCell></TableRow></TableHead>
                  <TableBody>
                    {argoApps.map(a => (
                      <TableRow key={a.name}>
                        <TableCell style={{ fontWeight: 500 }}>{a.name}</TableCell>
                        <TableCell><StatusIcon s={a.sync} /> {a.sync}</TableCell>
                        <TableCell><StatusIcon s={a.health} /> {a.health}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </InfoCard>
            </Grid>
            <Grid item xs={12}>
              <InfoCard title="Environments" subheader="AKS cluster status across regions">
                <Grid container spacing={2}>
                  {envs.map(e => (
                    <Grid item xs={12} md={4} key={e.name}>
                      <Box p={2} border="1px solid #e0e0e0" borderRadius={8}>
                        <Box display="flex" justifyContent="space-between" alignItems="center">
                          <Typography variant="h6" style={{ fontWeight: 600 }}>{e.name}</Typography>
                          <StatusOK />
                        </Box>
                        <Typography variant="body2" color="textSecondary">{e.cluster}</Typography>
                        <Box mt={1} display="flex" style={{ gap: 8 }}>
                          <Chip icon={<CloudIcon />} size="small" label={e.region} />
                          <Chip icon={<StorageIcon />} size="small" label={`${e.nodes} nodes`} variant="outlined" />
                          <Chip icon={<SpeedIcon />} size="small" label={`${e.pods} pods`} variant="outlined" />
                        </Box>
                      </Box>
                    </Grid>
                  ))}
                </Grid>
              </InfoCard>
            </Grid>
          </Grid>
        </Box>
      </Content>
    </Page>
  );
};

export default PlatformStatusPage;
