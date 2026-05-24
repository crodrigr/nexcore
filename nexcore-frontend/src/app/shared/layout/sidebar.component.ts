import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NavigationEnd, Router, RouterModule } from '@angular/router';
import { TranslocoModule, TranslocoService } from '@ngneat/transloco';
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
  private readonly translocoService: TranslocoService;

  constructor(
    private readonly menuService: MenuService,
    private readonly profileService: ProfileService,
    private readonly router: Router,
    translocoService: TranslocoService
  ) {
    this.sidebarMenus$ = this.menuService.getSidebarMenus();
    this.translocoService = translocoService;
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

  getMenuLabel(menu: MenuItem): string {
    const directTranslation = this.translateIfAvailable(menu.title);
    if (directTranslation) {
      return directTranslation;
    }

    const fallbackKey = `menu.${this.normalizeMenuKey(menu.name)}`;
    const fallbackTranslation = this.translateIfAvailable(fallbackKey);
    if (fallbackTranslation) {
      return fallbackTranslation;
    }

    return menu.title || menu.name;
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

  private translateIfAvailable(key: string | null | undefined): string | null {
    if (!key) {
      return null;
    }

    const translated = this.translocoService.translate(key);
    if (translated === key) {
      return null;
    }

    return translated;
  }

  private normalizeMenuKey(name: string | null | undefined): string {
    return (name || '')
      .replace(/([a-z])([A-Z])/g, '$1_$2')
      .replace(/[\s-]+/g, '_')
      .toLowerCase();
  }
}
