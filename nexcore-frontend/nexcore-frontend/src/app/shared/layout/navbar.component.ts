import { Component, OnInit, HostListener, ElementRef, ViewChild, createComponent, ApplicationRef, Injector, ComponentRef, EnvironmentInjector, inject } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ThemeToggleComponent } from '../theme/theme-toggle.component';
import { NotificationComponent } from '../components/notification/notification.component';
import { TranslocoModule, TranslocoService } from '@ngneat/transloco';

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

  constructor(private hostRef: ElementRef, private injector: Injector, private appRef: ApplicationRef, private environmentInjector: EnvironmentInjector, private router: Router) {}

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
      const lang = localStorage.getItem('nexcore-lang') || this.transloco.getActiveLang() || 'en';
      this.currentLang = lang;
      this.transloco.setActiveLang(lang);
    } catch (e) {}
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
      this.currentLang = lang;
      try { localStorage.setItem('nexcore-lang', lang); } catch (e) {}
      this.transloco.setActiveLang(lang);
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

  fallbackInline = false;

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
  }
}

