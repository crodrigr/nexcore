import { Component, signal, OnInit, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ThemeService } from './shared/theme/theme.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnInit {
  private themeService = inject(ThemeService);
  protected readonly title = signal('nexcore-frontend');
  
  ngOnInit(): void {
    // El ThemeService ya se inicializa automáticamente en el constructor
    console.log('Tema actual:', this.themeService.effectiveTheme());
  }
}
