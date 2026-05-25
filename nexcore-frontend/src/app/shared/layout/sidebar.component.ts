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
  expandedGroups: Record<string, boolean> = {};
  private readonly translocoService: TranslocoService;
  private readonly defaultIcon = 'menu';

  private readonly iconAliases: Record<string, string> = {
    'layout-dashboard': 'dashboard',
    'alert-circle': 'bell',
    'chart-bar': 'chart-bar',
    history: 'chart-bar',
    lock: 'settings',
    logout: 'close',
    menu: 'menu',
    profile: 'profile',
    radar: 'donut',
    settings: 'settings',
    shield: 'settings',
    user: 'profile',
    'user-circle': 'profile',
    users: 'users'
  };

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

  getIconUrl(menu: MenuItem): string {
    return this.buildIconUrl(menu.icon);
  }

  onIconError(event: Event): void {
    const img = event.target as HTMLImageElement | null;
    if (!img) {
      return;
    }

    const fallbackUrl = this.buildIconUrl(this.defaultIcon);
    if (img.src.endsWith('/menu.svg')) {
      return;
    }

    img.src = fallbackUrl;
  }

  setActiveMenu(route: string | null): void {
    this.activeRoute = this.normalizeRoute(route);
  }

  getMenuRoute(route: string | null): string | null {
    return this.normalizeRoute(route);
  }

  toggleGroup(menu: MenuItem): void {
    const groupId = this.getGroupKey(menu);
    this.expandedGroups[groupId] = !this.isGroupExpanded(menu);
  }

  isGroupExpanded(menu: MenuItem): boolean {
    const groupId = this.getGroupKey(menu);
    if (groupId in this.expandedGroups) {
      return this.expandedGroups[groupId];
    }

    const hasActiveChild = (menu.children || []).some(child => this.isMenuActive(child.route));
    return hasActiveChild;
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

  private buildIconUrl(icon: string | null | undefined): string {
    const normalizedIcon = (icon || this.defaultIcon).trim().toLowerCase().replace(/\.svg$/i, '');
    const aliasedIcon = this.iconAliases[normalizedIcon] || normalizedIcon;
    return `/assets/icons/${aliasedIcon}.svg`;
  }

  private getGroupKey(menu: MenuItem): string {
    return menu.id || menu.name || 'group';
  }
}
