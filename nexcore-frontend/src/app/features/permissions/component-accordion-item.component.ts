import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TranslocoModule } from '@ngneat/transloco';
import { AccessLevel, ComponentPermissionState } from './permissions.models';
import { AccessLevelPillComponent } from './access-level-pill.component';

@Component({
  selector: 'app-component-accordion-item',
  standalone: true,
  imports: [CommonModule, TranslocoModule, AccessLevelPillComponent],
  templateUrl: './component-accordion-item.component.html',
  styleUrls: ['./component-accordion-item.component.scss']
})
export class ComponentAccordionItemComponent {
  @Input() component!: ComponentPermissionState;
  @Output() accessChange = new EventEmitter<{ componentId: string; level: AccessLevel }>();
  @Output() elementAccessChange = new EventEmitter<{ componentId: string; elementId: string; level: AccessLevel }>();
  @Output() toggleExpand = new EventEmitter<string>();

  onAccessClick(level: AccessLevel): void {
    this.accessChange.emit({ componentId: this.component.componentId, level });
  }

  onElementClick(elementId: string, level: AccessLevel): void {
    this.elementAccessChange.emit({ componentId: this.component.componentId, elementId, level });
  }
}
