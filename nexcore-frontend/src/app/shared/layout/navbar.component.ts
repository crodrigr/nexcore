import { Component, OnInit, HostListener, ElementRef, ViewChild, createComponent, ApplicationRef, Injector, ComponentRef, EnvironmentInjector, inject, OnDestroy } from '@angular/core';
import { Subscription } from 'rxjs';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ThemeToggleComponent } from '../theme/theme-toggle.component';
import { NotificationComponent } from '../components/notification/notification.component';
import { TranslocoModule, TranslocoService } from '@ngneat/transloco';
import { ProfileService, MenuService, MenuItem, User } from '../services';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterModule, ThemeToggleComponent, NotificationComponent, TranslocoModule],
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.scss']
})
export class NavbarComponent implements OnInit {
  isCollapsed = false;
  showNotifications = false;
  showProfile = false;
  notificationAnchor: DOMRect | null = null;
  @ViewChild('notifBtn', { read: ElementRef, static: false }) notifBtn?: ElementRef<HTMLElement>;
  private notifRef: ComponentRef<NotificationComponent> | null = null;
  // TranslocoService injected for language switching
  private transloco = inject(TranslocoService);
  availableLangs = ['en', 'es'];
  currentLang = 'en';
  showLangMenu = false;
  
  // Menús y usuario dinámicos desde el backend
  navbarMenus$: Observable<MenuItem[]>;
  profileMenus$: Observable<MenuItem[]>;
  user$: Observable<User | null>;
  userInitials = 'NC';
  // Debug helper: render/console menu payloads
  debugMenuOutput = false;
  private subscriptions: Subscription[] = [];

  constructor(
    private hostRef: ElementRef, 
    private injector: Injector, 
    private appRef: ApplicationRef, 
    private environmentInjector: EnvironmentInjector, 
    private router: Router,
    private profileService: ProfileService,
    private menuService: MenuService
  ) {
    // Inicializar observables de menús
    this.navbarMenus$ = this.menuService.getNavbarMenus();
    this.profileMenus$ = this.menuService.getProfileMenus();
    this.user$ = this.profileService.user$;
  }

  ngOnInit(): void {
    try {
      const saved = localStorage.getItem('nexcore-sidebar-collapsed');
      if (saved === 'true') {
        document.body.classList.add('sidebar-collapsed');
        this.isCollapsed = true;
      }
    } catch (e) {
      // ignore (e.g., SSR or blocked storage)
    }

    // Initialize language from localStorage or transloco default
    try {
      const lang = (localStorage.getItem('nexcore-lang') || (this.transloco.getActiveLang() as string) || 'en') as string;
      this.currentLang = lang;
      this.transloco.setActiveLang(lang as string);
    } catch (e) {}
    
    // Cargar perfil desde el backend (o localStorage si ya existe)
    this.profileService.loadProfile().subscribe({
      next: (profile) => {
        if (profile) {
          console.log('[NavbarComponent] Profile loaded successfully');
        }
      },
      error: (err) => {
        console.error('[NavbarComponent] Error loading profile:', err);
      }
    });
    
    // Suscribirse a cambios de usuario para actualizar iniciales
    this.subscriptions.push(this.user$.subscribe(user => {
      if (user) {
        this.userInitials = this.profileService.getUserInitials();
      }
    }));

    // Debug: log emitted menu lists so we can inspect payloads
    this.subscriptions.push(this.profileMenus$.subscribe(pm => {
      console.debug('[Navbar] profileMenus emitted:', pm);
    }));
    this.subscriptions.push(this.navbarMenus$.subscribe(nm => {
      console.debug('[Navbar] navbarMenus emitted:', nm);
    }));
  }

  toggleSidebar() {
    const body = document.body;
    const collapsed = body.classList.toggle('sidebar-collapsed');
    this.isCollapsed = !!collapsed;
    try { localStorage.setItem('nexcore-sidebar-collapsed', String(this.isCollapsed)); } catch(e) {}

    // Also toggle a class on the sidebar element itself for higher-specificity rules
    const sidebar = document.querySelector('.sidebar');
    if (sidebar) {
      sidebar.classList.toggle('collapsed');
      if (this.isCollapsed) sidebar.classList.add('collapsed');
      else sidebar.classList.remove('collapsed');
    }
  }

  toggleNotifications() {
    this.showNotifications = !this.showNotifications;
    // compute anchor coordinates for dropdown positioning
    try {
      const el = this.notifBtn?.nativeElement;
      if (el) {
        this.notificationAnchor = el.getBoundingClientRect();
      } else {
        this.notificationAnchor = null;
      }
    } catch (e) {
      this.notificationAnchor = null;
    }

    if (this.showNotifications) {
      this.openNotificationOverlay();
    } else {
      this.closeNotificationOverlay();
    }
  }

  toggleProfile() {
    this.showProfile = !this.showProfile;
  }

  signOut() {
    // close the dropdown immediately
    this.showProfile = false;
    
    // Limpiar el perfil del servicio
    this.profileService.clearProfile();
    
    // attempt to clear common auth keys (non-destructive) and navigate to login
    try {
      localStorage.removeItem('auth');
      localStorage.removeItem('token');
      localStorage.removeItem('user');
    } catch (e) {}
    // navigate to the login route
    try {
      this.router.navigate(['/auth', 'login']);
    } catch (e) {
      // fallback to full reload if router navigation fails
      window.location.href = '/auth/login';
    }
  }

  changeLang(lang: string) {
    try {
      if (!lang) return;
      // Load translations for the selected language first, then activate it.
      this.transloco.load(lang).subscribe({
        next: () => {
          this.currentLang = lang as string;
          try { localStorage.setItem('nexcore-lang', lang as string); } catch (e) {}
          this.transloco.setActiveLang(lang as string);
        },
        error: (err) => {
          console.error('Failed to load language', lang, err);
          // fallback to activating anyway (may reuse cached translations)
          try { this.transloco.setActiveLang(lang as string); } catch(e) {}
        }
      });
    } catch (e) {
      console.error('changeLang failed', e);
    }
  }

  toggleLangMenu() {
    this.showLangMenu = !this.showLangMenu;
  }

  selectLang(lang: string) {
    this.changeLang(lang);
    this.showLangMenu = false;
  }
  
  /**
   * Navega a una ruta de menú
   * @param menu Item del menú
   */
  navigateToMenu(menu: MenuItem) {
    if (!menu.route) return;

    if (menu.name === 'Logout' || menu.route === '/auth/login') {
      this.signOut();
      return;
    }
    
    if (menu.item_type === 'EXTERNAL_LINK') {
      window.open(menu.route, '_blank');
    } else {
      this.router.navigate([menu.route]);
      // Cerrar dropdowns al navegar
      this.showProfile = false;
    }
  }
  
  /**
   * Verifica si un menú está deshabilitado (access: 'view')
   * @param menu Item del menú
   */
  isMenuDisabled(menu: MenuItem): boolean {
    return menu.access === 'view' || menu.access === 'hidden';
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

  fallbackInline = false;
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

  getIconUrl(menu: MenuItem): string {
    return this.buildIconUrl(menu.icon);
  }

  onIconError(event: Event): void {
    const img = event.target as HTMLImageElement | null;
    if (!img) {
      return;
    }

    if (img.src.endsWith('/menu.svg')) {
      return;
    }

    img.src = this.buildIconUrl(this.defaultIcon);
  }

  private openNotificationOverlay() {
    if (this.notifRef) return;
    try {
      console.log('opening notification overlay, anchor=', this.notificationAnchor);
      const compRef = createComponent(NotificationComponent, { environmentInjector: this.environmentInjector, elementInjector: this.injector });
      // pass anchor
      compRef.instance.anchor = this.notificationAnchor;
      // run change detection so host bindings are computed
      compRef.changeDetectorRef.detectChanges();
      // attach to app and body
      this.appRef.attachView(compRef.hostView);
      const domEl = (compRef.location && (compRef.location.nativeElement as HTMLElement)) || null;
      if (domEl) {
        domEl.style.zIndex = '1200';
        document.body.appendChild(domEl);
        console.log('notification appended to body', domEl);
      } else {
        console.warn('notification created but domEl is null');
      }
      this.notifRef = compRef;
      this.fallbackInline = false;
    } catch (err) {
      // if dynamic creation fails (browser/Angular mismatch), fallback to inline rendering
      console.error('openNotificationOverlay failed:', err);
      this.fallbackInline = true;
    }
  }

  private closeNotificationOverlay() {
    if (!this.notifRef) return;
    try {
      this.appRef.detachView(this.notifRef.hostView);
    } catch (e) {}
    try { this.notifRef.destroy(); } catch (e) {}
    this.notifRef = null;
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    // close when clicking outside the navbar component
    const target = event.target as Node | null;
    if (!target) return;
    const clickedInsideHost = this.hostRef.nativeElement.contains(target);
    const clickedInsideNotif = this.notifRef && this.notifRef.location && this.notifRef.location.nativeElement.contains(target);
    if (!clickedInsideHost && !clickedInsideNotif) {
      this.showNotifications = false;
      this.closeNotificationOverlay();
    }
  }

  ngOnDestroy(): void {
    this.closeNotificationOverlay();
    try {
      this.subscriptions.forEach(s => s.unsubscribe());
    } catch (e) {}
  }

  private translateIfAvailable(key: string | null | undefined): string | null {
    if (!key) {
      return null;
    }

    const translated = this.transloco.translate(key);
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
}

