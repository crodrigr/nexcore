import { Component, inject, AfterViewInit, ViewChild, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TranslocoModule } from '@ngneat/transloco';
import { NavbarComponent } from '../../shared/layout/navbar.component';
import { SidebarComponent } from '../../shared/layout/sidebar.component';
import { Router } from '@angular/router';
import { AuthService } from '../auth/service/auth.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, NavbarComponent, SidebarComponent, TranslocoModule],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
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
            labels: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
            datasets: [{
              label: 'Users',
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
            labels: ['Enterprise','SMB','Others'],
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
