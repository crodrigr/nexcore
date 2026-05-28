import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';
import { SidebarComponent } from './sidebar.component';
import { NavbarComponent } from './navbar.component';

@Component({
  selector: 'app-layout-shell',
  standalone: true,
  imports: [RouterModule, SidebarComponent, NavbarComponent],
  template: `
    <app-navbar></app-navbar>
    <app-sidebar></app-sidebar>
    <router-outlet></router-outlet>
  `,
  styles: [`:host { display: contents; }`]
})
export class LayoutShellComponent {}
