import { useState, useEffect } from 'react';
import { Content, Header, Page, InfoCard } from '@backstage/core-components';
import {
  Grid,
  makeStyles,
  Typography,
  Card,
  CardContent,
  LinearProgress,
  Chip,
  Box,
  CircularProgress,
} from '@material-ui/core';
import TrendingUpIcon from '@material-ui/icons/TrendingUp';
import CodeIcon from '@material-ui/icons/Code';
import CheckCircleIcon from '@material-ui/icons/CheckCircle';
import PeopleIcon from '@material-ui/icons/People';
import TimerIcon from '@material-ui/icons/Timer';
import GitHubIcon from '@material-ui/icons/GitHub';
import MergeTypeIcon from '@material-ui/icons/MergeType';
import RateReviewIcon from '@material-ui/icons/RateReview';
import { useApi, configApiRef, identityApiRef } from '@backstage/core-plugin-api';

import copilotLogo from '../../assets/logo-github-copilot.png';

const useStyles = makeStyles(theme => ({
  metricCard: { borderRadius: 12, height: '100%' },
  metricValue: { fontSize: '2.5rem', fontWeight: 700, color: '#0078D4', lineHeight: 1.2 },
  metricLabel: { fontSize: '0.85rem', color: theme.palette.text.secondary, marginTop: theme.spacing(0.5) },
  metricChange: { display: 'flex', alignItems: 'center', gap: 4, marginTop: theme.spacing(1), fontSize: '0.8rem', color: '#2e7d32' },
  progressBar: { borderRadius: 4, height: 8, marginTop: theme.spacing(1) },
  languageChip: { margin: theme.spacing(0.5) },
  headerBanner: {
    background: 'linear-gradient(135deg, #24292e 0%, #0078D4 100%)',
    borderRadius: 12, padding: theme.spacing(3, 4), color: '#fff',
    display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: theme.spacing(3),
  },
  copilotLogo: { height: 50 },
  barChart: { display: 'flex', alignItems: 'flex-end', gap: 6, height: 120, padding: theme.spacing(2, 0) },
  bar: { width: 24, borderRadius: '4px 4px 0 0', background: 'linear-gradient(180deg, #0078D4 0%, #00B7C3 100%)' },
  barLabel: { fontSize: '0.65rem', color: theme.palette.text.secondary, textAlign: 'center' as const, marginTop: 4 },
  liveTag: { backgroundColor: '#2e7d32', color: '#fff', fontWeight: 600, fontSize: '0.7rem' },
  mockTag: { backgroundColor: '#ed6c02', color: '#fff', fontWeight: 600, fontSize: '0.7rem' },
  activityRow: { display: 'flex', alignItems: 'center', gap: 8, padding: theme.spacing(1, 0), borderBottom: '1px solid #f0f0f0' },
}));

interface GitHubEvent {
  type: string;
  repo: { name: string };
  created_at: string;
  payload: { action?: string; pull_request?: { title: string; merged: boolean }; commits?: { message: string }[]; review?: { state: string } };
}

interface DevStats {
  totalCommits: number;
  totalPRs: number;
  mergedPRs: number;
  reviewsDone: number;
  reposContributed: string[];
  recentActivity: { type: string; repo: string; detail: string; date: string }[];
  languageBreakdown: { name: string; pct: number; color: string }[];
  isLive: boolean;
}

const GITHUB_ORG = '3horizons';

function useGitHubProductivity(): { data: DevStats; loading: boolean } {
  const config = useApi(configApiRef);
  const identityApi = useApi(identityApiRef);
  const [data, setData] = useState<DevStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const { userEntityRef } = await identityApi.getBackstageIdentity();
        const username = userEntityRef.split('/').pop() || 'guest';
        const backendUrl = config.getString('backend.baseUrl');
        const proxyBase = `${backendUrl}/api/proxy/github/api`;

        // Fetch user events (last 100)
        const eventsRes = await fetch(`${proxyBase}/users/${username}/events?per_page=100`);
        if (!eventsRes.ok) throw new Error('GitHub API unavailable');
        const events: GitHubEvent[] = await eventsRes.json();

        // Fetch user repos
        const reposRes = await fetch(`${proxyBase}/users/${username}/repos?per_page=100&sort=pushed`);
        const repos = await reposRes.json();

        // Calculate stats from events
        const pushEvents = events.filter(e => e.type === 'PushEvent');
        const prEvents = events.filter(e => e.type === 'PullRequestEvent');
        const reviewEvents = events.filter(e => e.type === 'PullRequestReviewEvent');
        const totalCommits = pushEvents.reduce((sum, e) => sum + (e.payload.commits?.length || 0), 0);
        const totalPRs = prEvents.filter(e => e.payload.action === 'opened').length;
        const mergedPRs = prEvents.filter(e => e.payload.pull_request?.merged).length;
        const reviewsDone = reviewEvents.length;
        const repoSet = new Set(events.map(e => e.repo.name));

        // Language breakdown from repos
        const langCount: Record<string, number> = {};
        for (const r of repos) {
          if (r.language) langCount[r.language] = (langCount[r.language] || 0) + 1;
        }
        const langTotal = Object.values(langCount).reduce((a: number, b: number) => a + b, 0) || 1;
        const langColors: Record<string, string> = {
          TypeScript: '#3178c6', JavaScript: '#f1e05a', Python: '#3572A5', Go: '#00ADD8',
          HCL: '#5C4EE5', Shell: '#89e051', Java: '#b07219', 'C#': '#178600', Dockerfile: '#384d54',
        };
        const languageBreakdown = Object.entries(langCount)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 6)
          .map(([name, count]) => ({
            name, pct: Math.round((count / langTotal) * 100),
            color: langColors[name] || '#888',
          }));

        // Recent activity (last 15)
        const recentActivity = events.slice(0, 15).map(e => {
          let type = e.type.replace('Event', '');
          let detail = '';
          if (e.type === 'PushEvent') detail = e.payload.commits?.[0]?.message || 'push';
          if (e.type === 'PullRequestEvent') detail = `${e.payload.action}: ${e.payload.pull_request?.title || ''}`;
          if (e.type === 'PullRequestReviewEvent') detail = `review: ${e.payload.review?.state || ''}`;
          if (e.type === 'CreateEvent') detail = 'branch/tag created';
          if (e.type === 'IssuesEvent') detail = `issue ${e.payload.action}`;
          return { type, repo: e.repo.name.split('/').pop() || e.repo.name, detail: detail.slice(0, 80), date: new Date(e.created_at).toLocaleDateString() };
        });

        setData({ totalCommits, totalPRs, mergedPRs, reviewsDone, reposContributed: [...repoSet], recentActivity, languageBreakdown, isLive: true });
      } catch {
        // Fallback to mock data
        setData({
          totalCommits: 247, totalPRs: 38, mergedPRs: 31, reviewsDone: 52,
          reposContributed: ['three-horizons-accelerator', 'platform-config', 'api-gateway', 'ml-pipeline', 'docs-site'],
          recentActivity: [
            { type: 'Push', repo: 'three-horizons-accelerator', detail: 'feat: add copilot metrics page', date: '2/24/2026' },
            { type: 'PullRequest', repo: 'three-horizons-accelerator', detail: 'opened: enterprise backstage upgrade', date: '2/24/2026' },
            { type: 'PullRequestReview', repo: 'platform-config', detail: 'review: approved', date: '2/23/2026' },
            { type: 'Push', repo: 'api-gateway', detail: 'fix: CORS config for production', date: '2/23/2026' },
            { type: 'PullRequest', repo: 'ml-pipeline', detail: 'merged: mlops training pipeline v2', date: '2/22/2026' },
            { type: 'Push', repo: 'docs-site', detail: 'docs: update architecture guide', date: '2/22/2026' },
            { type: 'PullRequestReview', repo: 'api-gateway', detail: 'review: changes_requested', date: '2/21/2026' },
            { type: 'Push', repo: 'three-horizons-accelerator', detail: 'feat: golden path templates', date: '2/21/2026' },
          ],
          languageBreakdown: [
            { name: 'TypeScript', pct: 35, color: '#3178c6' },
            { name: 'Python', pct: 25, color: '#3572A5' },
            { name: 'HCL', pct: 18, color: '#5C4EE5' },
            { name: 'YAML', pct: 12, color: '#cb171e' },
            { name: 'Shell', pct: 7, color: '#89e051' },
            { name: 'Go', pct: 3, color: '#00ADD8' },
          ],
          isLive: false,
        });
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [config, identityApi]);

  return { data: data!, loading };
}

// Copilot metrics (org-level API requires admin scope — use mock with live indicator)
const copilotMetrics = {
  acceptanceRate: 38.2, totalSuggestions: 12847,
  linesAccepted: 28430, activeUsers: 24, totalSeats: 30, timeSavedHours: 186,
  weeklyTrend: [65, 72, 58, 80, 74, 68, 85, 92, 78, 88, 95, 82],
  weekLabels: ['W1','W2','W3','W4','W5','W6','W7','W8','W9','W10','W11','W12'],
  editors: [
    { name: 'VS Code', pct: 68 }, { name: 'JetBrains', pct: 22 },
    { name: 'Neovim', pct: 7 }, { name: 'Other', pct: 3 },
  ],
  chat: { totalChats: 3420, avgTurns: 4.2, codeBlocks: 2180,
    intents: ['Code explanation', 'Bug fix', 'Test generation', 'Refactoring', 'Documentation'] },
};

const MetricCard = ({ value, label, icon, change }: { value: string; label: string; icon: React.ReactNode; change?: string }) => {
  const classes = useStyles();
  return (
    <Card className={classes.metricCard} variant="outlined">
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="flex-start">
          <div>
            <Typography className={classes.metricValue}>{value}</Typography>
            <Typography className={classes.metricLabel}>{label}</Typography>
            {change && <Typography className={classes.metricChange}><TrendingUpIcon style={{ fontSize: 16 }} /> {change}</Typography>}
          </div>
          <Box style={{ color: '#0078D4', opacity: 0.3 }}>{icon}</Box>
        </Box>
      </CardContent>
    </Card>
  );
};

const CopilotMetricsPage = () => {
  const classes = useStyles();
  const { data: dev, loading } = useGitHubProductivity();
  const maxT = Math.max(...copilotMetrics.weeklyTrend);

  if (loading) {
    return (
      <Page themeId="tool">
        <Header title="Developer Productivity" subtitle="Loading your data..." />
        <Content>
          <Box display="flex" justifyContent="center" alignItems="center" minHeight={400}>
            <CircularProgress />
          </Box>
        </Content>
      </Page>
    );
  }

  return (
    <Page themeId="tool">
      <Header title="Developer Productivity & Copilot Metrics" subtitle="Your GitHub activity + AI-powered productivity insights" />
      <Content>
        {/* Header Banner */}
        <div className={classes.headerBanner}>
          <div>
            <Typography variant="h5" style={{ fontWeight: 700 }}>
              Productivity Dashboard
              <Chip size="small" label={dev?.isLive ? 'LIVE DATA' : 'DEMO DATA'} className={dev?.isLive ? classes.liveTag : classes.mockTag} style={{ marginLeft: 12, verticalAlign: 'middle' }} />
            </Typography>
            <Typography variant="body2" style={{ opacity: 0.8, marginTop: 4 }}>
              {dev?.isLive ? 'Real-time data from GitHub API' : 'Sample data — set GITHUB_TOKEN for live metrics'}
            </Typography>
          </div>
          <img className={classes.copilotLogo} src={copilotLogo} alt="GitHub Copilot" />
        </div>

        {/* Developer Productivity Section */}
        <Typography variant="h6" style={{ fontWeight: 600, marginBottom: 16 }}>
          <GitHubIcon style={{ verticalAlign: 'middle', marginRight: 8 }} />
          Your GitHub Activity (last 90 days)
        </Typography>
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={String(dev?.totalCommits || 0)} label="Commits" icon={<CodeIcon style={{ fontSize: 40 }} />} />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={String(dev?.totalPRs || 0)} label="PRs Opened" icon={<MergeTypeIcon style={{ fontSize: 40 }} />} />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={String(dev?.mergedPRs || 0)} label="PRs Merged" icon={<CheckCircleIcon style={{ fontSize: 40 }} />} />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={String(dev?.reviewsDone || 0)} label="Code Reviews" icon={<RateReviewIcon style={{ fontSize: 40 }} />} />
          </Grid>
        </Grid>

        <Box mt={3}>
          <Grid container spacing={3}>
            {/* Recent Activity Feed */}
            <Grid item xs={12} md={8}>
              <InfoCard title="Recent Activity" subheader={`Last ${dev?.recentActivity.length || 0} events`}>
                {dev?.recentActivity.map((a, i) => (
                  <div key={i} className={classes.activityRow}>
                    <Chip
                      size="small"
                      label={a.type}
                      style={{
                        backgroundColor: a.type === 'Push' ? '#0078D4' : a.type.includes('Review') ? '#5C2D91' : '#2e7d32',
                        color: '#fff', minWidth: 90,
                      }}
                    />
                    <Typography variant="body2" style={{ fontWeight: 500, minWidth: 140 }}>{a.repo}</Typography>
                    <Typography variant="body2" color="textSecondary" style={{ flex: 1 }} noWrap>{a.detail}</Typography>
                    <Typography variant="caption" color="textSecondary">{a.date}</Typography>
                  </div>
                ))}
              </InfoCard>
            </Grid>

            {/* Language Breakdown */}
            <Grid item xs={12} md={4}>
              <InfoCard title="Your Languages" subheader="By repository count">
                {dev?.languageBreakdown.map(l => (
                  <Box key={l.name} mb={1.5}>
                    <Box display="flex" justifyContent="space-between">
                      <Typography variant="body2">{l.name}</Typography>
                      <Typography variant="body2" style={{ fontWeight: 600 }}>{l.pct}%</Typography>
                    </Box>
                    <LinearProgress className={classes.progressBar} variant="determinate" value={l.pct} style={{ backgroundColor: `${l.color}20` }} />
                  </Box>
                ))}
              </InfoCard>

              <Box mt={2}>
                <InfoCard title="Repos Contributed" subheader={`${dev?.reposContributed.length || 0} repositories`}>
                  <Box display="flex" flexWrap="wrap" style={{ gap: 4 }}>
                    {dev?.reposContributed.slice(0, 12).map(r => (
                      <Chip key={r} size="small" label={r.split('/').pop()} variant="outlined" className={classes.languageChip} />
                    ))}
                  </Box>
                </InfoCard>
              </Box>
            </Grid>
          </Grid>
        </Box>

        {/* Copilot Metrics Section */}
        <Box mt={4}>
          <Typography variant="h6" style={{ fontWeight: 600, marginBottom: 16 }}>
            <img src={copilotLogo} alt="" style={{ height: 20, verticalAlign: 'middle', marginRight: 8 }} />
            GitHub Copilot — Organization Metrics
            <Chip size="small" label="ORG-LEVEL" className={classes.mockTag} style={{ marginLeft: 12, verticalAlign: 'middle' }} />
          </Typography>
        </Box>
        <Grid container spacing={3}>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={`${copilotMetrics.acceptanceRate}%`} label="Acceptance Rate" icon={<CheckCircleIcon style={{ fontSize: 40 }} />} change="+3.1% vs last month" />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={copilotMetrics.totalSuggestions.toLocaleString()} label="Total Suggestions" icon={<CodeIcon style={{ fontSize: 40 }} />} change="+18% vs last month" />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={`${copilotMetrics.activeUsers}/${copilotMetrics.totalSeats}`} label="Active Seats" icon={<PeopleIcon style={{ fontSize: 40 }} />} change="80% utilization" />
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <MetricCard value={`${copilotMetrics.timeSavedHours}h`} label="Dev Time Saved" icon={<TimerIcon style={{ fontSize: 40 }} />} change="+24h vs last month" />
          </Grid>
        </Grid>
        <Box mt={3}>
          <Grid container spacing={3}>
            <Grid item xs={12} md={8}>
              <InfoCard title="Weekly Acceptance Trend" subheader="Suggestions accepted per week (last 12 weeks)">
                <div className={classes.barChart}>
                  {copilotMetrics.weeklyTrend.map((val, i) => (
                    <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flex: 1 }}>
                      <div className={classes.bar} style={{ height: `${(val / maxT) * 100}%` }} />
                      <Typography className={classes.barLabel}>{copilotMetrics.weekLabels[i]}</Typography>
                    </div>
                  ))}
                </div>
              </InfoCard>
            </Grid>
            <Grid item xs={12} md={4}>
              <InfoCard title="Editor Usage" subheader="Copilot by IDE">
                {copilotMetrics.editors.map(e => (
                  <Box key={e.name} mb={1.5}>
                    <Box display="flex" justifyContent="space-between">
                      <Typography variant="body2">{e.name}</Typography>
                      <Typography variant="body2" style={{ fontWeight: 600 }}>{e.pct}%</Typography>
                    </Box>
                    <LinearProgress className={classes.progressBar} variant="determinate" value={e.pct} />
                  </Box>
                ))}
              </InfoCard>
            </Grid>
            <Grid item xs={12} md={6}>
              <InfoCard title="Copilot Chat" subheader="Chat usage insights (last 28 days)">
                <Grid container spacing={2}>
                  <Grid item xs={6}>
                    <Typography variant="h4" style={{ fontWeight: 700, color: '#0078D4' }}>{copilotMetrics.chat.totalChats.toLocaleString()}</Typography>
                    <Typography variant="caption" color="textSecondary">Total Chats</Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="h4" style={{ fontWeight: 700, color: '#00B7C3' }}>{copilotMetrics.chat.avgTurns}</Typography>
                    <Typography variant="caption" color="textSecondary">Avg Turns/Chat</Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="h4" style={{ fontWeight: 700, color: '#5C2D91' }}>{copilotMetrics.chat.codeBlocks.toLocaleString()}</Typography>
                    <Typography variant="caption" color="textSecondary">Code Blocks</Typography>
                  </Grid>
                  <Grid item xs={6}>
                    <Typography variant="subtitle2" gutterBottom>Top Intents</Typography>
                    {copilotMetrics.chat.intents.map(intent => <Chip key={intent} label={intent} size="small" className={classes.languageChip} variant="outlined" />)}
                  </Grid>
                </Grid>
              </InfoCard>
            </Grid>
            <Grid item xs={12} md={6}>
              <InfoCard title="ROI Summary" subheader="Return on Copilot investment">
                <Box py={1}>
                  {[
                    { label: 'Monthly Cost', value: `$${(copilotMetrics.totalSeats * 19).toLocaleString()}`, color: '#666' },
                    { label: 'Time Saved', value: `${copilotMetrics.timeSavedHours}h`, color: '#2e7d32' },
                    { label: 'Cost Saved', value: `$${(copilotMetrics.timeSavedHours * 75).toLocaleString()}`, color: '#2e7d32' },
                    { label: 'Net ROI', value: `${Math.round(((copilotMetrics.timeSavedHours * 75) / (copilotMetrics.totalSeats * 19) - 1) * 100)}%`, color: '#0078D4' },
                    { label: 'Lines Generated', value: copilotMetrics.linesAccepted.toLocaleString(), color: '#5C2D91' },
                  ].map(item => (
                    <Box key={item.label} display="flex" justifyContent="space-between" py={1} borderBottom="1px solid #f0f0f0">
                      <Typography variant="body2">{item.label}</Typography>
                      <Typography variant="body2" style={{ fontWeight: 700, color: item.color }}>{item.value}</Typography>
                    </Box>
                  ))}
                </Box>
              </InfoCard>
            </Grid>
          </Grid>
        </Box>
      </Content>
    </Page>
  );
};

export default CopilotMetricsPage;