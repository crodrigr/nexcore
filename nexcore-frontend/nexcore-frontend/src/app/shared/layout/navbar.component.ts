import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ThemeToggleComponent } from '../theme/theme-toggle.component';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterModule, ThemeToggleComponent],
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.scss']
})
export class NavbarComponent implements OnInit {
  isCollapsed = false;

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
}

