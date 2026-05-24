import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map, shareReplay } from 'rxjs/operators';
import { ProfileService } from './profile.service';

@Injectable({
  providedIn: 'root'
})
export class PermissionService {
  
  constructor(private profileService: ProfileService) {}
  
  /**
   * Verifica si el usuario puede VER un componente
   * @param component Nombre del componente (ej: 'dashboard')
   * @returns Observable<boolean>
   */
  canView$(component: string): Observable<boolean> {
    return this.getComponentAccess$(component).pipe(
      map(access => access === 'view' || access === 'execute')
    );
  }
  
  /**
   * Verifica si el usuario puede EJECUTAR acciones en un componente
   * Sobrecarga: sin elementKey valida el componente completo
   * @param component Nombre del componente
   * @returns Observable<boolean>
   */
  canExecute$(component: string): Observable<boolean>;
  /**
   * Verifica si el usuario puede EJECUTAR un elemento específico
   * Sobrecarga: con elementKey valida un elemento particular
   * @param component Nombre del componente
   * @param elementKey Identificador del elemento (ej: 'btn-create-user')
   * @returns Observable<boolean>
   */
  canExecute$(component: string, elementKey: string): Observable<boolean>;
  
  canExecute$(component: string, elementKey?: string): Observable<boolean> {
    if (elementKey) {
      // Validación a nivel elemento
      return this.getElementAccess$(component, elementKey).pipe(
        map(access => access === 'execute')
      );
    } else {
      // Validación a nivel componente
      return this.getComponentAccess$(component).pipe(
        map(access => access === 'execute')
      );
    }
  }
  
  /**
   * Verifica si el usuario puede VER un elemento específico
   * @param component Nombre del componente
   * @param elementKey Identificador del elemento
   * @returns Observable<boolean>
   */
  canViewElement$(component: string, elementKey: string): Observable<boolean> {
    return this.getElementAccess$(component, elementKey).pipe(
      map(access => access === 'view' || access === 'execute')
    );
  }
  
  /**
   * Obtiene el nivel de acceso de un componente
   * @param component Nombre del componente
   * @returns Observable<'execute' | 'view' | 'hidden'>
   */
  private getComponentAccess$(component: string): Observable<'execute' | 'view' | 'hidden'> {
    return this.profileService.permissions$.pipe(
      map(permissions => {
        const permission = permissions.find(p => p.component === component);
        return permission?.access ?? 'hidden';
      }),
      shareReplay(1)
    );
  }
  
  /**
   * Obtiene el nivel de acceso de un elemento
   * @param component Nombre del componente
   * @param elementKey Identificador del elemento
   * @returns Observable<'execute' | 'view' | 'hidden'>
   */
  private getElementAccess$(component: string, elementKey: string): Observable<'execute' | 'view' | 'hidden'> {
    return this.profileService.permissions$.pipe(
      map(permissions => {
        const permission = permissions.find(p => p.component === component);
        if (!permission) return 'hidden';
        
        const element = permission.elements.find(e => e.element_key === elementKey);
        return element?.access ?? 'hidden';
      }),
      shareReplay(1)
    );
  }
  
  /**
   * Verifica si el usuario puede acceder a una ruta (usado por el Guard)
   * @param component Nombre del componente
   * @returns Promise<boolean>
   */
  async canAccessRoute(component: string): Promise<boolean> {
    return new Promise((resolve) => {
      this.profileService.permissions$.pipe(
        map(permissions => {
          const permission = permissions.find(p => p.component === component);
          
          if (!permission) {
            console.warn(`[PermissionService] No permission found for component: ${component}`);
            return false;
          }
          
          const canAccess = permission.access === 'view' || permission.access === 'execute';
          
          if (!canAccess) {
            console.warn(`[PermissionService] Access denied for component: ${component} (access: ${permission.access})`);
          }
          
          return canAccess;
        })
      ).subscribe(result => resolve(result));
    });
  }
}
