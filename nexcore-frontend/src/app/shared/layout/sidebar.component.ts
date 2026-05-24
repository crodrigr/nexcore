import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NavigationEnd, Router, RouterModule } from '@angular/router';
import { TranslocoModule } from '@ngneat/transloco';
import { Observable } from 'rxjs';
import { filter } from 'rxjs/operators';
import { MenuItem, MenuService, ProfileService } from '../services';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule, TranslocoModule],
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.scss']
})
export class SidebarComponent implements OnInit {
  sidebarMenus$: Observable<MenuItem[]>;
  activeRoute: string | null = null;

  constructor(
    private readonly menuService: MenuService,
    private readonly profileService: ProfileService,
    private readonly router: Router
  ) {
    this.sidebarMenus$ = this.menuService.getSidebarMenus();
  }

  ngOnInit(): void {
    this.activeRoute = this.normalizeRoute(this.router.url);

    this.profileService.loadProfile().subscribe({
      error: (error) => {
        console.error('[SidebarComponent] Error loading profile:', error);
      }
    });

    this.router.events
      .pipe(filter((event): event is NavigationEnd => event instanceof NavigationEnd))
      .subscribe(event => {
        this.activeRoute = this.normalizeRoute(event.urlAfterRedirects);
      });
  }

  isMenuDisabled(menu: MenuItem): boolean {
    return menu.access === 'view';
  }

  getIconName(menu: MenuItem): string {
    return menu.icon || 'default';
  }

  setActiveMenu(route: string | null): void {
    this.activeRoute = this.normalizeRoute(route);
  }

  isMenuActive(route: string | null): boolean {
    const normalizedRoute = this.normalizeRoute(route);
    if (!normalizedRoute || !this.activeRoute) {
      return false;
    }

    return this.activeRoute === normalizedRoute;
  }

  private normalizeRoute(route: string | null): string | null {
    if (!route) {
      return null;
    }

    if (route === '/graphics') {
      return '/dashboard';
    }

    return route;
  }
}
