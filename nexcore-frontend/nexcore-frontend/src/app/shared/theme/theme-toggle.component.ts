import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ThemeService } from './theme.service';

@Component({
  selector: 'app-theme-toggle',
  standalone: true,
  imports: [CommonModule],
  template: `
    <button
      class="theme-toggle"
      [attr.aria-label]="'Cambiar tema: ' + effectiveTheme()"
      (click)="toggleTheme()"
    >
      @if (effectiveTheme() === 'light') {
        <!-- Icono de Luna (modo oscuro disponible) -->
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
        </svg>
      } @else {
        <!-- Icono de Sol (modo claro disponible) -->
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="5" />
          <line x1="12" y1="1" x2="12" y2="3" />
          <line x1="12" y1="21" x2="12" y2="23" />
          <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" />
          <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" />
          <line x1="1" y1="12" x2="3" y2="12" />
          <line x1="21" y1="12" x2="23" y2="12" />
          <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" />
          <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" />
        </svg>
      }
    </button>
  `,
  styles: [`
    .theme-toggle {
      background: var(--color-surface);
      border: 1px solid var(--color-border-light);
      border-radius: var(--radius-md);
      padding: var(--spacing-2);
      cursor: pointer;
      transition: all 0.2s ease;
      display: flex;
      align-items: center;
      justify-content: center;
      
      &:hover {
        background: var(--color-surface-hover);
        border-color: var(--color-border-medium);
      }
      
      &:focus-visible {
        outline: none;
        box-shadow: var(--shadow-focus);
      }
    }
    
    .icon {
      width: 20px;
      height: 20px;
      color: var(--color-text-primary);
      stroke-width: 2;
    }
  `]
})
export class ThemeToggleComponent {
  private themeService = inject(ThemeService);
  
  effectiveTheme = this.themeService.effectiveTheme;
  
  toggleTheme(): void {
    this.themeService.toggleTheme();
  }
}
