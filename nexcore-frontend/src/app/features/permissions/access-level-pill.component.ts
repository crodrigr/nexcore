import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AccessLevel } from './permissions.models';

@Component({
  selector: 'app-access-level-pill',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="access-pills">
      <button
        *ngFor="let level of levels"
        class="access-pill"
        [class.active]="value === level"
        [ngClass]="level"
        type="button"
        (click)="levelChange.emit(level)">
        {{ level.toUpperCase() }}
      </button>
    </div>
  `,
  styles: [`
    .access-pills {
      display: inline-flex;
      border: 1px solid var(--color-border-light);
      border-radius: 8px;
      overflow: hidden;
    }
    .access-pill {
      padding: 5px 10px;
      font-size: .7rem;
      font-weight: 700;
      letter-spacing: .04em;
      background: var(--color-bg-secondary);
      border: none;
      cursor: pointer;
      transition: background .12s, color .12s;
      white-space: nowrap;
    }
    .access-pill:not(:last-child) { border-right: 1px solid var(--color-border-light); }
    .access-pill:hover { filter: brightness(.93); }
    .access-pill:not(.active) { color: var(--color-text-secondary); }
    .access-pill.active.hidden  { background: #6b7280; color: #fff; }
    .access-pill.active.view    { background: var(--color-interactive-primary); color: #fff; }
    .access-pill.active.execute { background: #10b981; color: #fff; }
  `]
})
export class AccessLevelPillComponent {
  @Input() value: AccessLevel = 'hidden';
  @Output() levelChange = new EventEmitter<AccessLevel>();
  readonly levels: AccessLevel[] = ['hidden', 'view', 'execute'];
}
