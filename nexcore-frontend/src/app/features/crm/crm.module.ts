import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { CommonModule } from '@angular/common';
import { CrmComponent } from './crm.component';
import { SidebarComponent } from '../../shared/layout/sidebar.component';
import { NavbarComponent } from '../../shared/layout/navbar.component';

const routes: Routes = [
  {
    path: '',
    component: CrmComponent
  }
];

@NgModule({
  imports: [
    CommonModule,
    SidebarComponent,
    NavbarComponent,
    CrmComponent,
    RouterModule.forChild(routes)
  ]
})
export class CrmModule {}
