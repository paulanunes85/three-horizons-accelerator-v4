import {
  HomePageStarredEntities,
  HomePageToolkit,
} from '@backstage/plugin-home';
import { Content, Header, Page } from '@backstage/core-components';
import { Grid, makeStyles, Typography, Box, Button, Card, CardContent, CardActionArea } from '@material-ui/core';
import CategoryIcon from '@material-ui/icons/Category';
import CodeIcon from '@material-ui/icons/Code';
import MenuBookIcon from '@material-ui/icons/MenuBook';
import ExtensionIcon from '@material-ui/icons/Extension';
import AddCircleOutlineIcon from '@material-ui/icons/AddCircleOutline';
import CloudIcon from '@material-ui/icons/Cloud';
import TrendingUpIcon from '@material-ui/icons/TrendingUp';
import AssessmentIcon from '@material-ui/icons/Assessment';
import FavoriteIcon from '@material-ui/icons/Favorite';
import StorageIcon from '@material-ui/icons/Storage';
import SecurityIcon from '@material-ui/icons/Security';
import SettingsEthernetIcon from '@material-ui/icons/SettingsEthernet';
import EmojiObjectsIcon from '@material-ui/icons/EmojiObjects';
import BuildIcon from '@material-ui/icons/Build';
import AutorenewIcon from '@material-ui/icons/Autorenew';
import BubbleChartIcon from '@material-ui/icons/BubbleChart';
import ArrowForwardIcon from '@material-ui/icons/ArrowForward';

import logoWhite from '../../assets/logo-msft-github-white.png';

const useStyles = makeStyles(theme => ({
  hero: {
    background: 'linear-gradient(135deg, #0078D4 0%, #005A9E 40%, #00B7C3 100%)',
    borderRadius: 20,
    padding: theme.spacing(6, 5),
    color: '#fff',
    position: 'relative' as const,
    overflow: 'hidden',
    marginBottom: theme.spacing(4),
  },
  heroDecor: {
    position: 'absolute' as const,
    right: -40,
    top: -40,
    width: 320,
    height: 320,
    borderRadius: '50%',
    background: 'rgba(255,255,255,0.06)',
  },
  heroDecor2: {
    position: 'absolute' as const,
    right: 60,
    bottom: -60,
    width: 200,
    height: 200,
    borderRadius: '50%',
    background: 'rgba(255,255,255,0.04)',
  },
  heroLogo: {
    height: 40,
    opacity: 0.9,
    position: 'relative' as const,
    zIndex: 1,
    marginTop: theme.spacing(3),
  },
  heroTitle: {
    fontWeight: 800,
    fontSize: '2.2rem',
    lineHeight: 1.2,
    marginBottom: theme.spacing(1.5),
    position: 'relative' as const,
    zIndex: 1,
  },
  heroSub: {
    fontSize: '1.05rem',
    opacity: 0.9,
    lineHeight: 1.6,
    maxWidth: 560,
    position: 'relative' as const,
    zIndex: 1,
  },
  heroCta: {
    marginTop: theme.spacing(3),
    position: 'relative' as const,
    zIndex: 1,
    display: 'flex',
    gap: theme.spacing(2),
  },
  ctaBtn: {
    borderRadius: 10,
    padding: theme.spacing(1.2, 3),
    fontWeight: 600,
    textTransform: 'none' as const,
    fontSize: '0.95rem',
  },
  ctaPrimary: {
    backgroundColor: '#fff',
    color: '#0078D4',
    '&:hover': { backgroundColor: '#f0f0f0' },
  },
  ctaSecondary: {
    borderColor: 'rgba(255,255,255,0.6)',
    color: '#fff',
    '&:hover': { borderColor: '#fff', backgroundColor: 'rgba(255,255,255,0.1)' },
  },
  statsRow: {
    display: 'flex',
    gap: theme.spacing(4),
    marginTop: theme.spacing(4),
    position: 'relative' as const,
    zIndex: 1,
  },
  stat: {
    textAlign: 'center' as const,
  },
  statValue: {
    fontWeight: 800,
    fontSize: '1.6rem',
    lineHeight: 1,
  },
  statLabel: {
    fontSize: '0.75rem',
    opacity: 0.8,
    marginTop: 4,
  },
  horizonCard: {
    borderRadius: 16,
    height: '100%',
    transition: 'transform 0.2s, box-shadow 0.2s',
    '&:hover': {
      transform: 'translateY(-4px)',
      boxShadow: '0 8px 30px rgba(0,0,0,0.12)',
    },
  },
  horizonHeader: {
    padding: theme.spacing(3),
    color: '#fff',
    borderRadius: '16px 16px 0 0',
    display: 'flex',
    alignItems: 'center',
    gap: theme.spacing(1.5),
  },
  horizonIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.2)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  horizonTag: {
    fontSize: '0.65rem',
    fontWeight: 700,
    letterSpacing: 1.5,
    textTransform: 'uppercase' as const,
    opacity: 0.8,
  },
  horizonTitle: {
    fontWeight: 700,
    fontSize: '1.1rem',
  },
  horizonBody: {
    padding: theme.spacing(2, 3, 3),
  },
  horizonFeature: {
    display: 'flex',
    alignItems: 'center',
    gap: theme.spacing(1),
    padding: theme.spacing(0.6, 0),
    color: theme.palette.text.secondary,
    fontSize: '0.85rem',
  },
  horizonFeatureIcon: {
    fontSize: 16,
    color: theme.palette.primary.main,
  },
  sectionTitle: {
    fontWeight: 700,
    fontSize: '1.15rem',
    marginBottom: theme.spacing(2),
    display: 'flex',
    alignItems: 'center',
    gap: theme.spacing(1),
  },
  h1Gradient: { background: 'linear-gradient(135deg, #005A9E, #0078D4)' },
  h2Gradient: { background: 'linear-gradient(135deg, #0078D4, #00B7C3)' },
  h3Gradient: { background: 'linear-gradient(135deg, #5C2D91, #B4009E)' },
}));

const HomePage = () => {
  const classes = useStyles();

  return (
    <Page themeId="home">
      <Header title="Open Horizons" subtitle="Agentic DevOps Platform — Powered by Backstage" />
      <Content>
        {/* Hero Section */}
        <div className={classes.hero}>
          <div className={classes.heroDecor} />
          <div className={classes.heroDecor2} />
          <Typography className={classes.heroTitle} variant="h3">
            Your Developer Platform
          </Typography>
          <Typography className={classes.heroSub}>
            Build, deploy, and manage services with Golden Path templates,
            integrated documentation, and AI-powered developer experiences —
            all from a single pane of glass.
          </Typography>
          <div className={classes.heroCta}>
            <Button variant="contained" className={`${classes.ctaBtn} ${classes.ctaPrimary}`} href="/create" startIcon={<AddCircleOutlineIcon />}>
              Create New Service
            </Button>
            <Button variant="outlined" className={`${classes.ctaBtn} ${classes.ctaSecondary}`} href="/catalog">
              Explore Catalog
            </Button>
          </div>
          <img className={classes.heroLogo} src={logoWhite} alt="Microsoft + GitHub" />
          <div className={classes.statsRow}>
            <div className={classes.stat}>
              <Typography className={classes.statValue}>22</Typography>
              <Typography className={classes.statLabel}>Templates</Typography>
            </div>
            <div className={classes.stat}>
              <Typography className={classes.statValue}>3</Typography>
              <Typography className={classes.statLabel}>Horizons</Typography>
            </div>
            <div className={classes.stat}>
              <Typography className={classes.statValue}>13</Typography>
              <Typography className={classes.statLabel}>Portal Pages</Typography>
            </div>
            <div className={classes.stat}>
              <Typography className={classes.statValue}>99.9%</Typography>
              <Typography className={classes.statLabel}>Uptime</Typography>
            </div>
          </div>
        </div>

        <Grid container spacing={3}>
          {/* Three Horizons Cards */}
          <Grid item xs={12}>
            <Typography className={classes.sectionTitle}>
              <BubbleChartIcon color="primary" /> The Three Horizons
            </Typography>
          </Grid>

          <Grid item xs={12} md={4}>
            <Card className={classes.horizonCard} variant="outlined">
              <CardActionArea href="/catalog?filters[kind]=component&filters[user]=all">
                <div className={`${classes.horizonHeader} ${classes.h1Gradient}`}>
                  <div className={classes.horizonIcon}><StorageIcon /></div>
                  <div>
                    <Typography className={classes.horizonTag}>HORIZON 1</Typography>
                    <Typography className={classes.horizonTitle}>Foundation</Typography>
                  </div>
                </div>
                <CardContent className={classes.horizonBody}>
                  <Typography variant="body2" color="textSecondary" gutterBottom>
                    Core infrastructure and CI/CD foundations for everything you build.
                  </Typography>
                  <div className={classes.horizonFeature}><SecurityIcon className={classes.horizonFeatureIcon} /> AKS clusters & networking</div>
                  <div className={classes.horizonFeature}><CodeIcon className={classes.horizonFeatureIcon} /> CI/CD pipelines & security scanning</div>
                  <div className={classes.horizonFeature}><CloudIcon className={classes.horizonFeatureIcon} /> Infrastructure as Code (Terraform)</div>
                  <div className={classes.horizonFeature}><SettingsEthernetIcon className={classes.horizonFeatureIcon} /> Identity & secrets management</div>
                  <Box mt={1.5} display="flex" alignItems="center" style={{ color: '#0078D4', fontWeight: 600, fontSize: '0.85rem' }}>
                    6 templates <ArrowForwardIcon style={{ fontSize: 16, marginLeft: 4 }} />
                  </Box>
                </CardContent>
              </CardActionArea>
            </Card>
          </Grid>

          <Grid item xs={12} md={4}>
            <Card className={classes.horizonCard} variant="outlined">
              <CardActionArea href="/create">
                <div className={`${classes.horizonHeader} ${classes.h2Gradient}`}>
                  <div className={classes.horizonIcon}><BuildIcon /></div>
                  <div>
                    <Typography className={classes.horizonTag}>HORIZON 2</Typography>
                    <Typography className={classes.horizonTitle}>Enhancement</Typography>
                  </div>
                </div>
                <CardContent className={classes.horizonBody}>
                  <Typography variant="body2" color="textSecondary" gutterBottom>
                    Platform services, GitOps, microservices, and developer experience.
                  </Typography>
                  <div className={classes.horizonFeature}><AutorenewIcon className={classes.horizonFeatureIcon} /> ArgoCD GitOps deployments</div>
                  <div className={classes.horizonFeature}><ExtensionIcon className={classes.horizonFeatureIcon} /> API gateways & microservices</div>
                  <div className={classes.horizonFeature}><TrendingUpIcon className={classes.horizonFeatureIcon} /> Observability & monitoring</div>
                  <div className={classes.horizonFeature}><MenuBookIcon className={classes.horizonFeatureIcon} /> Golden Path templates</div>
                  <Box mt={1.5} display="flex" alignItems="center" style={{ color: '#00B7C3', fontWeight: 600, fontSize: '0.85rem' }}>
                    9 templates <ArrowForwardIcon style={{ fontSize: 16, marginLeft: 4 }} />
                  </Box>
                </CardContent>
              </CardActionArea>
            </Card>
          </Grid>

          <Grid item xs={12} md={4}>
            <Card className={classes.horizonCard} variant="outlined">
              <CardActionArea href="/create">
                <div className={`${classes.horizonHeader} ${classes.h3Gradient}`}>
                  <div className={classes.horizonIcon}><EmojiObjectsIcon /></div>
                  <div>
                    <Typography className={classes.horizonTag}>HORIZON 3</Typography>
                    <Typography className={classes.horizonTitle}>Innovation</Typography>
                  </div>
                </div>
                <CardContent className={classes.horizonBody}>
                  <Typography variant="body2" color="textSecondary" gutterBottom>
                    AI capabilities, intelligent agents, and next-gen workflows.
                  </Typography>
                  <div className={classes.horizonFeature}><BubbleChartIcon className={classes.horizonFeatureIcon} /> Azure AI Foundry agents</div>
                  <div className={classes.horizonFeature}><CategoryIcon className={classes.horizonFeatureIcon} /> RAG applications</div>
                  <div className={classes.horizonFeature}><AssessmentIcon className={classes.horizonFeatureIcon} /> MLOps & evaluation pipelines</div>
                  <div className={classes.horizonFeature}><FavoriteIcon className={classes.horizonFeatureIcon} /> Multi-agent systems</div>
                  <Box mt={1.5} display="flex" alignItems="center" style={{ color: '#B4009E', fontWeight: 600, fontSize: '0.85rem' }}>
                    7 templates <ArrowForwardIcon style={{ fontSize: 16, marginLeft: 4 }} />
                  </Box>
                </CardContent>
              </CardActionArea>
            </Card>
          </Grid>

          {/* Quick Actions & Starred */}
          <Grid item xs={12}>
            <Typography className={classes.sectionTitle} style={{ marginTop: 8 }}>
              <TrendingUpIcon color="primary" /> Quick Access
            </Typography>
          </Grid>

          <Grid item xs={12} md={6}>
            <HomePageToolkit
              title="Quick Actions"
              tools={[
                { url: '/create', label: 'Create', icon: <AddCircleOutlineIcon /> },
                { url: '/catalog', label: 'Catalog', icon: <CategoryIcon /> },
                { url: '/api-docs', label: 'APIs', icon: <ExtensionIcon /> },
                { url: '/docs', label: 'Docs', icon: <MenuBookIcon /> },
                { url: '/copilot-metrics', label: 'Copilot', icon: <AssessmentIcon /> },
                { url: '/platform-status', label: 'Status', icon: <FavoriteIcon /> },
                { url: '/catalog-graph', label: 'Graph', icon: <TrendingUpIcon /> },
                { url: '/learning', label: 'Learn', icon: <CodeIcon /> },
              ]}
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <HomePageStarredEntities />
          </Grid>
        </Grid>
      </Content>
    </Page>
  );
};

export default HomePage;
