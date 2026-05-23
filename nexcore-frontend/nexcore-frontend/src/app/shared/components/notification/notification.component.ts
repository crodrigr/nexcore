import { Component, Input, HostBinding } from '@angular/core';
import { CommonModule } from '@angular/common';

interface NotificationItem {
  id: string;
  title: string;
  body?: string;
  time: string;
  unread?: boolean;
}

@Component({
  selector: 'app-notification',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './notification.component.html',
  styleUrls: ['./notification.component.scss']
})
export class NotificationComponent {
  items: NotificationItem[] = [
    { id: '1', title: 'Successful login', body: 'Signed in from Madrid', time: '2h', unread: true },
    { id: '2', title: 'New tenant created', body: 'Tenant "Acme Corp" added', time: '1d', unread: true },
    { id: '3', title: 'Backup completed', body: 'Automatic backup finished', time: '3d', unread: false },
  ];

  private _anchor: DOMRect | null = null;

  @HostBinding('style.position') hostPosition = 'fixed';
  @HostBinding('style.top') hostTop?: string;
  @HostBinding('style.left') hostLeft?: string;
  @HostBinding('style.right') hostRight?: string;
  @HostBinding('style.zIndex') hostZ = '1100';

  @Input()
  set anchor(a: DOMRect | null) {
    this._anchor = a;
    this.computePosition();
  }
  get anchor() { return this._anchor; }

  private computePosition() {
    if (!this._anchor) {
      this.hostTop = '72px';
      this.hostRight = '16px';
      this.hostLeft = undefined;
      return;
    }
    const top = Math.round(this._anchor.bottom + 8) + 'px';
    const dropdownWidth = 320;
    const centeredLeft = Math.round(this._anchor.left + (this._anchor.width / 2) - (dropdownWidth / 2));
    const maxLeft = Math.round(window.innerWidth - dropdownWidth - 8);
    const clampedLeft = Math.min(Math.max(centeredLeft, 8), maxLeft);
    this.hostTop = top;
    this.hostLeft = clampedLeft + 'px';
    this.hostRight = undefined;
    // diagnostic
    console.debug('notification position computed', { top: this.hostTop, left: this.hostLeft, anchor: this._anchor });
  }

  markAllRead() {
    this.items = this.items.map(i => ({ ...i, unread: false }));
  }

  toggleRead(i: NotificationItem) {
    i.unread = !i.unread;
  }
}
