import { Component } from '@angular/core';
import { SidebarComponent } from '../../shared/layout/sidebar.component';
import { NavbarComponent } from '../../shared/layout/navbar.component';

@Component({
  selector: 'app-crm',
  standalone: true,
  imports: [SidebarComponent, NavbarComponent],
  templateUrl: './crm.component.html',
  styleUrls: ['./crm.component.scss']
})
export class CrmComponent {}
