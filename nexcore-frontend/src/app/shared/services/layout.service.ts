import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class LayoutService {
  private readonly _collapsed = new BehaviorSubject<boolean>(false);
  readonly collapsed$ = this._collapsed.asObservable();

  get isCollapsed(): boolean {
    return this._collapsed.value;
  }

  init(): void {
    try {
      const saved = localStorage.getItem('nexcore-sidebar-collapsed');
      const collapsed = saved === 'true';
      this._collapsed.next(collapsed);
      if (collapsed) {
        document.body.classList.add('sidebar-collapsed');
      } else {
        document.body.classList.remove('sidebar-collapsed');
      }
    } catch (e) {}
  }

  toggle(): void {
    const next = !this._collapsed.value;
    this._collapsed.next(next);
    if (next) {
      document.body.classList.add('sidebar-collapsed');
    } else {
      document.body.classList.remove('sidebar-collapsed');
    }
    try {
      localStorage.setItem('nexcore-sidebar-collapsed', String(next));
    } catch (e) {}
  }
}
