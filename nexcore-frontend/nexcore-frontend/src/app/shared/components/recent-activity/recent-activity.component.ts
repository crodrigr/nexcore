import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivityService, RecentActivity } from '../../services/activity.service';

@Component({
  selector: 'app-recent-activity',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './recent-activity.component.html',
  styleUrls: ['./recent-activity.component.scss']
})
export class RecentActivityComponent implements OnInit {
  activities: RecentActivity[] = [];

  constructor(private activityService: ActivityService) {}

  ngOnInit(): void {
    this.activityService.getRecentActivities().subscribe(data => this.activities = data);
  }

  statusClass(s: RecentActivity['status']) {
    return {
      'success': 'badge success',
      'error': 'badge error',
      'pending': 'badge pending'
    }[s];
  }
}
