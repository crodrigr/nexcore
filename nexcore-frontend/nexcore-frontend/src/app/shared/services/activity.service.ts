import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';

export type ActivityStatus = 'success' | 'error' | 'pending';

export interface RecentActivity {
  initials: string;
  name: string;
  action: string;
  tenant: string;
  time: string;
  status: ActivityStatus;
}

@Injectable({ providedIn: 'root' })
export class ActivityService {
  constructor() {}

  getRecentActivities(): Observable<RecentActivity[]> {
    const data: RecentActivity[] = [
      { initials: 'JD', name: 'Juan Delgado', action: 'Menu Update', tenant: 'Restaurant Alpha', time: '5 min ago', status: 'success' },
      { initials: 'MR', name: 'Maria Rivera', action: 'User Creation', tenant: 'Global Tech', time: '12 min ago', status: 'success' },
      { initials: 'AG', name: 'Andrés García', action: 'Failed Login', tenant: 'NexCore Core', time: '18 min ago', status: 'error' },
      { initials: 'LC', name: 'Lucía Castro', action: 'System Backup', tenant: 'Global Tech', time: '45 min ago', status: 'success' },
      { initials: 'RP', name: 'Roberto Pino', action: 'API Configuration', tenant: 'Restaurant Alpha', time: '1 h ago', status: 'pending' }
    ];
    return of(data);
  }
}
