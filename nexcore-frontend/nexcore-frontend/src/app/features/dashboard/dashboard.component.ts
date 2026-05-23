import { Component, inject, AfterViewInit, ViewChild, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NavbarComponent } from '../../shared/layout/navbar.component';
import { SidebarComponent } from '../../shared/layout/sidebar.component';
import { Router } from '@angular/router';
import { AuthService } from '../../shared/services/auth.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, NavbarComponent, SidebarComponent],
  template: `
<app-navbar></app-navbar>

<div class="page-wrap">
  <div class="layout">
    <app-sidebar></app-sidebar>

    <main class="content">
      <header class="page-header">
        <h1>Dashboard</h1>
        <p class="subtitle">Bienvenido de vuelta, Administrador</p>
      </header>


      <section class="top-stats">
        <div class="stat-card">
          <div class="left">
            <div class="icon-circle bg-blue">👥</div>
          </div>
          <div class="body">
            <div class="label">TOTAL USUARIOS</div>
            <div class="value">1,234</div>
          </div>
          <div class="trend positive">+12.5%</div>
        </div>

        <div class="stat-card">
          <div class="left">
            <div class="icon-circle bg-pink">🏷️</div>
          </div>
          <div class="body">
            <div class="label">TENANTS ACTIVOS</div>
            <div class="value">42</div>
          </div>
          <div class="trend positive">+3</div>
        </div>

        <div class="stat-card">
          <div class="left">
            <div class="icon-circle bg-beige">⚡</div>
          </div>
          <div class="body">
            <div class="label">SESIONES HOY</div>
            <div class="value">567</div>
          </div>
          <div class="trend negative">-2.3%</div>
        </div>

        <div class="stat-card">
          <div class="left">
            <div class="icon-circle bg-lightblue">✔️</div>
          </div>
          <div class="body">
            <div class="label">TASA DE ÉXITO</div>
            <div class="value">98.5%</div>
          </div>
          <div class="trend positive">+0.5%</div>
        </div>
      </section>


      <section class="main-grid">
        <div class="large-card chart-card">
          <div class="card-header">Usuarios Activos
            <div class="toggle-group"><button class="pill">Semanal</button><button class="pill active">Mensual</button></div>
          </div>
          <div class="chart-placeholder">
            <canvas #barCanvas></canvas>
          </div>
        </div>

        <div class="small-card donut-card">
          <div class="card-header">Distribución por Tenant</div>
          <div class="donut-placeholder">
            <canvas #donutCanvas></canvas>
            <div class="donut-center">42<br><span class="small">Total</span></div>
          </div>
          <ul class="legend">
            <li><span class="dot blue"></span> Enterprise <span class="percent">65%</span></li>
            <li><span class="dot pink"></span> SMB <span class="percent">25%</span></li>
            <li><span class="dot gray"></span> Otros <span class="percent">10%</span></li>
          </ul>
        </div>
      </section>

      <section class="recent-activity-card card">
        <div class="card-header">
          <h2>Recent Activity</h2>
          <a class="view-all" href="#">View all</a>
        </div>

        <div class="table-responsive">
          <table class="activity-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Action</th>
                <th>Tenant</th>
                <th>Date</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="user-cell">
                  <div class="avatar">JD</div>
                  <div class="user-info"><div class="name">Juan Delgado</div></div>
                </td>
                <td>Menu Update</td>
                <td>Restaurant Alpha</td>
                <td>5 min ago</td>
                <td><span class="badge success">SUCCESS</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">MR</div>
                  <div class="user-info"><div class="name">Maria Rivera</div></div>
                </td>
                <td>User Creation</td>
                <td>Global Tech</td>
                <td>12 min ago</td>
                <td><span class="badge success">SUCCESS</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">AG</div>
                  <div class="user-info"><div class="name">Andrés García</div></div>
                </td>
                <td>Failed Login</td>
                <td>NexCore Core</td>
                <td>18 min ago</td>
                <td><span class="badge error">ERROR</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">LC</div>
                  <div class="user-info"><div class="name">Lucía Castro</div></div>
                </td>
                <td>System Backup</td>
                <td>Global Tech</td>
                <td>45 min ago</td>
                <td><span class="badge success">SUCCESS</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">RP</div>
                  <div class="user-info"><div class="name">Roberto Pino</div></div>
                </td>
                <td>API Configuration</td>
                <td>Restaurant Alpha</td>
                <td>1 h ago</td>
                <td><span class="badge pending">PENDING</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">AL</div>
                  <div class="user-info"><div class="name">Ana López</div></div>
                </td>
                <td>Password Reset</td>
                <td>BlueMoon</td>
                <td>2 h ago</td>
                <td><span class="badge success">SUCCESS</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">CM</div>
                  <div class="user-info"><div class="name">Carlos Mejía</div></div>
                </td>
                <td>Role Update</td>
                <td>GreenFields</td>
                <td>2 h ago</td>
                <td><span class="badge success">SUCCESS</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">SM</div>
                  <div class="user-info"><div class="name">Sofía Martínez</div></div>
                </td>
                <td>Tenant Creation</td>
                <td>Global Tech</td>
                <td>3 h ago</td>
                <td><span class="badge pending">PENDING</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">DT</div>
                  <div class="user-info"><div class="name">Diego Torres</div></div>
                </td>
                <td>Export Data</td>
                <td>NexCore Core</td>
                <td>Today</td>
                <td><span class="badge success">SUCCESS</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">ER</div>
                  <div class="user-info"><div class="name">Elena Ruiz</div></div>
                </td>
                <td>Import Catalog</td>
                <td>BlueMoon</td>
                <td>Today</td>
                <td><span class="badge success">SUCCESS</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">PG</div>
                  <div class="user-info"><div class="name">Pablo Gómez</div></div>
                </td>
                <td>Permission Change</td>
                <td>GreenFields</td>
                <td>Today</td>
                <td><span class="badge success">SUCCESS</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">MF</div>
                  <div class="user-info"><div class="name">Mariana Flores</div></div>
                </td>
                <td>Invoice Generation</td>
                <td>Global Tech</td>
                <td>4 h ago</td>
                <td><span class="badge success">SUCCESS</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">OV</div>
                  <div class="user-info"><div class="name">Óscar Vega</div></div>
                </td>
                <td>Theme Update</td>
                <td>NexCore Core</td>
                <td>6 h ago</td>
                <td><span class="badge success">SUCCESS</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">PS</div>
                  <div class="user-info"><div class="name">Patricia Salazar</div></div>
                </td>
                <td>API Key Rotation</td>
                <td>Restaurant Alpha</td>
                <td>8 h ago</td>
                <td><span class="badge error">ERROR</span></td>
              </tr>

              <tr>
                <td class="user-cell">
                  <div class="avatar">IO</div>
                  <div class="user-info"><div class="name">Ignacio Ortega</div></div>
                </td>
                <td>Scheduled Job</td>
                <td>BlueMoon</td>
                <td>Yesterday</td>
                <td><span class="badge pending">PENDING</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

    </main>
  </div>
</div>
  `,
  styles: [
    `
.layout {
  display: flex;
  position: relative;
  z-index: 0;
  isolation: isolate;
}

.page-wrap {
  display: flex;
  flex-direction: column;
  min-height: calc(100vh - var(--navbar-height,64px));
}
.content {
  flex: 1 1 auto;
  /* reserve space for fixed navbar only; header stays in normal flow */
  padding: calc(var(--navbar-height,64px) + 12px) 32px 28px 32px;
  background: linear-gradient(180deg, rgba(13,71,161,0.02), transparent 40%), var(--color-bg-primary);
  min-height: calc(100vh - var(--navbar-height,64px));
}

.page-header {
  position: static;
  background: transparent;
  padding-top: 0;
}

.dashboard-card {
  background: var(--color-surface);
  border-radius: 12px;
  padding: 20px 22px;
  box-shadow: var(--shadow-sm);
  max-width: 980px;
  width: 100%;
  margin-bottom: 22px;
  border: 1px solid var(--color-border-light);
}

.actions {
  margin-top: var(--spacing-4);
}

.btn-secondary {
  background: transparent;
  border: 1px solid var(--color-border-medium);
  color: var(--color-text-primary);
  padding: var(--spacing-2) var(--spacing-4);
  border-radius: var(--radius-md);
  cursor: pointer;
}

.summary-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 18px;
}

.summary-cards .card {
  background: var(--color-surface-elevated, var(--color-surface));
  padding: 18px 18px;
  border-radius: 10px;
  text-align: left;
  display:flex; align-items:center; gap:14px; justify-content:space-between;
}

.summary-card-left { display:flex; gap:12px; align-items:center }
.summary-card-icon { width:44px; height:44px; border-radius:10px; display:flex; align-items:center; justify-content:center }
.summary-card-body { flex:1 }
.summary-card .big { font-size:28px; font-weight:800 }

.summary-cards .big {
  display: block;
  font-size: 28px;
  font-weight: var(--font-weight-bold);
  margin-top: var(--spacing-2);
}

.page-header h1 { font-size:var(--font-size-4xl); margin:0 0 6px 0; font-weight:var(--font-weight-bold); color:var(--color-text-primary) }
.page-header .subtitle { color:var(--color-text-secondary); margin-top:6px; font-size:var(--font-size-lg) }

.top-stats { display:grid; grid-template-columns: repeat(4, 1fr); gap:18px; margin:10px 0 22px }
.stat-card { background:var(--color-surface); padding:16px; border-radius:10px; box-shadow:0 6px 18px rgba(15,23,42,0.04); display:flex; align-items:center; position:relative; border:1px solid var(--color-border-light) }
.stat-card .left { margin-right:12px }
.icon-circle { width:44px; height:44px; border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:18px }
.bg-blue { background: linear-gradient(180deg,var(--bg-blue-start),var(--bg-blue-end)) }
.bg-pink { background: linear-gradient(180deg,var(--bg-pink-start),var(--bg-pink-end)) }
.bg-beige { background: linear-gradient(180deg,var(--bg-beige-start),var(--bg-beige-end)) }
.bg-lightblue { background: linear-gradient(180deg,var(--bg-lightblue-start),var(--bg-lightblue-end)) }
.label { font-size:12px; color:var(--color-text-secondary); letter-spacing:0.02em }
.value { font-size:24px; font-weight:900; margin-top:6px; color:var(--color-text-primary) }
.trend { position:absolute; top:12px; right:12px; font-weight:700; font-size:12px }
.trend.positive { color:var(--color-success) }
.trend.negative { color:var(--color-error) }

.main-grid { display:grid; grid-template-columns: 2fr 1fr; gap:22px; margin-bottom:20px }
.large-card, .small-card { background:var(--color-surface); padding:20px; border-radius:12px; box-shadow:var(--shadow-sm); border:1px solid var(--color-border-light) }

/* Card header subtle background */
.card-header { background: transparent; padding-bottom: 6px }
.card-header { display:flex; justify-content:space-between; align-items:center; font-weight:700; margin-bottom:14px }
.card-header h3, .card-header h2 { margin:0 }
.chart-placeholder { height:360px; background: linear-gradient(180deg, rgba(0,0,0,0.03), transparent); border-radius:12px; display:flex; align-items:center; justify-content:center; color:var(--color-text-secondary); padding:14px }
.chart-placeholder canvas { width:100% !important; height:320px !important }
.donut-placeholder { height:220px; display:flex; align-items:center; justify-content:center; position:relative }
.donut-placeholder canvas { width:100% !important; height:220px !important; max-width:220px }
.donut-center { position:absolute; top:50%; left:50%; transform:translate(-50%,-50%); display:flex; flex-direction:column; align-items:center; justify-content:center; font-weight:800; font-size:20px; color:var(--color-text-primary) }
.donut-center .small { font-weight:600; font-size:12px; color:var(--color-text-secondary) }
.legend { list-style:none; padding:0; margin:12px 0 0 0 }
.legend li { display:flex; justify-content:space-between; padding:6px 0 }
.dot { width:12px; height:12px; border-radius:50%; display:inline-block; margin-right:8px }
.dot.blue { background: var(--color-interactive-primary) }
.dot.pink { background: var(--color-interactive-secondary) }
.dot.gray { background: var(--color-border-medium) }
.percent { color:var(--color-text-secondary) }

/* Toggle pills for weekly/monthly */
.toggle-group { display:inline-flex; gap:8px; align-items:center; background: var(--toggle-bg, rgba(15,23,42,0.04)); padding:4px; border-radius:999px }
.pill { background: transparent; border: none; padding:6px 12px; border-radius:999px; cursor:pointer; font-weight:700; color:var(--color-text-primary); font-size:13px }
.pill:hover { filter:brightness(0.98) }
.pill.active { background: var(--color-interactive-primary); color: #fff; box-shadow: 0 6px 18px rgba(10,66,140,0.12) }

.activity-card { margin-top:18px }
.activity-header { display:flex; justify-content:space-between; align-items:center }
.activity-table { width:100%; border-collapse:collapse; margin-top:12px }
.activity-table thead th { text-align:left; padding:12px; background:transparent; color:var(--color-text-secondary); font-weight:700 }
.activity-table tbody td { padding:14px; border-top:1px solid rgba(15,23,42,0.04) }
.avatar-sm { width:44px; height:44px; border-radius:22px; background:var(--color-bg-secondary); display:inline-flex; align-items:center; justify-content:center; margin-right:12px; color:var(--color-interactive-primary); font-weight:700 }
.user { display:flex; align-items:center }
.badge { padding:6px 12px; border-radius:14px; font-weight:700; font-size:12px }
.badge.success { background: var(--color-success-bg); color: var(--color-success) }
.badge.error { background: var(--color-error-bg); color: var(--color-error) }
.badge.pending { background: var(--color-warning-bg); color: var(--color-warning-700) }

/* Recent Activity static table styles (pixel-tuned) */
.recent-activity-card { margin-top: 18px; width: 100%; max-width: none; }
.recent-activity-card.card { padding: 14px 18px; border-radius: 12px; border: 1px solid var(--color-border-light); box-shadow: var(--shadow-sm); background: var(--color-surface); }
.recent-activity-card .card-header { display:flex; align-items:center; justify-content:space-between; padding-bottom:12px; border-bottom:1px solid var(--color-border-light) }
.recent-activity-card .card-header h2 { font-size:16px; margin:0; color:var(--color-text-primary); font-weight:800 }
.recent-activity-card .view-all { color:var(--color-interactive-primary); text-decoration:none; font-size:13px }
.table-responsive {
  overflow: visible;
  max-height: none;
}
.activity-table { width:100%; border-collapse:collapse; margin-top:12px }
.activity-table thead th { text-align:left; padding:12px 16px; background: #f8fafc; color: #6b7280; font-weight:800; font-size:13px; border-bottom: 1px solid rgba(15,23,42,0.06); }
.activity-table tbody td { padding:14px 16px; border-bottom:1px solid var(--color-border-light) }
.activity-table tbody tr { vertical-align:middle }
.activity-table tbody tr:hover { background: rgba(15,23,42,0.03) }
.user-cell { display:flex; align-items:center; gap:12px }
.avatar { width:40px; height:40px; border-radius:20px; background:var(--color-border-medium); display:inline-flex; align-items:center; justify-content:center; color:var(--color-text-inverse); font-weight:800; font-size:13px }
.user-info .name { font-weight:800; color:var(--color-text-primary); font-size:14px }
.user-info .sub { color:var(--color-text-secondary); font-size:12px }
.activity-table .badge { display:inline-block; padding:6px 12px; border-radius:999px; font-weight:800; font-size:12px }
.badge.success { background: rgba(34,197,94,0.12); color: var(--color-success) }
.badge.error { background: rgba(239,68,68,0.08); color: var(--color-error) }
.badge.pending { background: rgba(234,179,8,0.12); color: var(--color-warning-700) }
.activity-table tbody td .percent { color:var(--color-text-secondary); font-size:13px }

@media (max-width: 880px) {
  .main-grid { grid-template-columns: 1fr }
  .summary-cards { grid-template-columns: repeat(2, 1fr) }
}


`]
})
export class DashboardComponent {
  private router = inject(Router);
  private authService = inject(AuthService);
  @ViewChild('barCanvas', { static: false }) barCanvas?: ElementRef<HTMLCanvasElement>;
  @ViewChild('donutCanvas', { static: false }) donutCanvas?: ElementRef<HTMLCanvasElement>;

  profile = this.authService.userProfile;

  ngAfterViewInit(): void {
    this.initCharts();
  }

  async initCharts(): Promise<void> {
    try {
      const ChartModule = await import('chart.js/auto');
      const Chart = ChartModule.default;

      // Apply theme-aware colors to Chart defaults
      const bodyStyle = getComputedStyle(document.body);
      const textColor = bodyStyle.getPropertyValue('--color-text-primary')?.trim() || 'var(--color-text-primary)';
      const gridColor = bodyStyle.getPropertyValue('--color-border-light')?.trim() || 'var(--color-border-light)';
      const chartBarLight = bodyStyle.getPropertyValue('--chart-bar-light')?.trim() || 'var(--chart-bar-light)';
      const chartPrimary = bodyStyle.getPropertyValue('--chart-primary')?.trim() || 'var(--chart-primary)';
      const chartPink = bodyStyle.getPropertyValue('--chart-pink')?.trim() || 'var(--chart-pink)';
      const chartGray = bodyStyle.getPropertyValue('--chart-gray')?.trim() || 'var(--chart-gray)';
      if (Chart && Chart.defaults) {
        Chart.defaults.color = textColor;
        Chart.defaults.borderColor = gridColor;
      }

      // Bar chart (Usuarios Activos)
      if (this.barCanvas?.nativeElement) {
        const ctx = this.barCanvas.nativeElement.getContext('2d') as CanvasRenderingContext2D;
        const lightFill = chartBarLight || 'rgba(173,216,255,0.6)';
        const darkFill = chartPrimary || '#0a66a8';

        const bgColors = [lightFill, lightFill, lightFill, lightFill, lightFill, lightFill, darkFill];

        const valueLabelPlugin = {
          id: 'valueLabelPlugin',
          afterDatasetsDraw(chart: any) {
            const ctx2 = chart.ctx;
            chart.data.datasets.forEach((dataset: any, dsIndex: number) => {
              const meta = chart.getDatasetMeta(dsIndex);
              meta.data.forEach((bar: any, index: number) => {
                const data = dataset.data[index];
                const x = bar.x;
                const y = bar.y;
                let labelY = y - 8;
                ctx2.save();
                ctx2.font = '600 12px Inter, system-ui, Roboto, Helvetica, Arial';
                ctx2.textAlign = 'center';
                const minLabelY = 16;
                if (labelY < minLabelY) {
                  // draw inside the bar if too close to the top
                  labelY = bar.y + 12;
                  ctx2.fillStyle = '#fff';
                } else {
                  ctx2.fillStyle = textColor || '#0f172a';
                }
                ctx2.fillText(String(data), x, labelY);
                ctx2.restore();
              });
            });
          }
        };

        const barValues = [60,40,80,70,95,60,120];
        const maxBar = Math.max(...barValues);
        const suggestedMax = Math.ceil(maxBar * 1.12);

        new Chart(ctx, {
          type: 'bar',
          data: {
            labels: ['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'],
            datasets: [{
              label: 'Usuarios',
              data: barValues,
              backgroundColor: bgColors,
              borderRadius: 10,
              barPercentage: 0.56,
              maxBarThickness: 40
            }],
          },
          plugins: [valueLabelPlugin],
          options: {
            responsive: true,
            maintainAspectRatio: false,
            layout: { padding: { top: 28 } },
            plugins: { legend: { display: false }, tooltip: { enabled: true, backgroundColor: 'rgba(0,0,0,0.75)', titleColor: textColor, bodyColor: textColor } },
            scales: {
              x: { grid: { display: false }, ticks: { color: textColor } },
              y: { grid: { color: gridColor }, ticks: { color: textColor }, suggestedMax }
            }
          }
        });
        // register inline plugin for labels
        try { (Chart as any).register(valueLabelPlugin); } catch (e) { /* ignore if registration not needed */ }
      }

      // Donut chart (Distribución por Tenant)
      if (this.donutCanvas?.nativeElement) {
        const ctxD = this.donutCanvas.nativeElement.getContext('2d') as CanvasRenderingContext2D;
        new Chart(ctxD, {
          type: 'doughnut',
          data: {
            labels: ['Enterprise','SMB','Otros'],
            datasets: [{ data: [65,25,10], backgroundColor: [chartPrimary,chartPink,chartGray], cutout: '72%' }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            elements: { arc: { borderWidth: 12, borderColor: 'rgba(0,0,0,0.04)' } }
          }
        });
      }
    } catch (e) {
      // Chart.js not installed — dejar placeholders visibles
      // No throw to avoid breaking the page
      // eslint-disable-next-line no-console
      console.warn('Chart.js not available. Install with: npm install chart.js', e);
    }
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/auth/login']);
  }
}
