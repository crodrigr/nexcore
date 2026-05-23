import { Injectable, signal, effect, inject, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export type Theme = 'light' | 'dark' | 'auto';

@Injectable({
  providedIn: 'root'
})
export class ThemeService {
  private readonly STORAGE_KEY = 'nexcore-theme';
  private platformId = inject(PLATFORM_ID);
  
  // Signal reactivo para el tema actual (por defecto: 'light' para igualar diseño)
  theme = signal<Theme>(this.getStoredTheme() || 'light');
  
  // Computed signal que resuelve el tema efectivo (auto → light/dark según OS)
  effectiveTheme = signal<'light' | 'dark'>('light');
  
  constructor() {
    if (isPlatformBrowser(this.platformId)) {
      this.initializeTheme();
    }
  }
  
  private initializeTheme(): void {
    // Detectar preferencia del sistema
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    
    // Actualizar tema efectivo cuando cambie el signal o la preferencia del OS
    effect(() => {
      const theme = this.theme();
      let effective: 'light' | 'dark';
      
      if (theme === 'auto') {
        effective = mediaQuery.matches ? 'dark' : 'light';
      } else {
        effective = theme;
      }
      
      this.effectiveTheme.set(effective);
      this.applyTheme(effective);
    });
    
    // Escuchar cambios en la preferencia del sistema
    mediaQuery.addEventListener('change', (e) => {
      if (this.theme() === 'auto') {
        const effective = e.matches ? 'dark' : 'light';
        this.effectiveTheme.set(effective);
        this.applyTheme(effective);
      }
    });
  }
  
  setTheme(theme: Theme): void {
    this.theme.set(theme);
    if (isPlatformBrowser(this.platformId)) {
      localStorage.setItem(this.STORAGE_KEY, theme);
    }
  }
  
  toggleTheme(): void {
    const current = this.effectiveTheme();
    this.setTheme(current === 'light' ? 'dark' : 'light');
  }
  
  private applyTheme(theme: 'light' | 'dark'): void {
    if (isPlatformBrowser(this.platformId)) {
      document.body.setAttribute('data-theme', theme);
    }
  }
  
  private getStoredTheme(): Theme | null {
    if (isPlatformBrowser(this.platformId)) {
      const stored = localStorage.getItem(this.STORAGE_KEY);
      return stored as Theme | null;
    }
    return null;
  }
}
