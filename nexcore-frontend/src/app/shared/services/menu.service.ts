import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ProfileService, MenuItem } from './profile.service';

@Injectable({
  providedIn: 'root'
})
export class MenuService {
  
  constructor(private profileService: ProfileService) {}
  
  /**
   * Obtiene los menús filtrados por ubicación (navbar, profile, sidebar, footer)
   * Solo incluye menús con acceso 'execute' o 'view' (excluye 'hidden')
   * Ordena por order_index
   * @param location Ubicación del menú
   * @returns Observable<MenuItem[]>
   */
  getMenusByLocation(location: string): Observable<MenuItem[]> {
    return this.profileService.menus$.pipe(
      map(menus => {
        // Filtrado robusto: incluye menús que tengan location==location
        // o que tengan descendientes con esa ubicación.
        const filterRecursive = (items: MenuItem[]): MenuItem[] => {
          return items
            .map(item => {
              const children = item.children ? filterRecursive(item.children) : [];
              const matchesLocation = item.location === location;
              const hasVisibleChildren = children.length > 0;
              const isAccessible = item.access === 'execute' || item.access === 'view';

              if (!isAccessible) return null;

              // GROUP solo se incluye si tiene hijos visibles (evita grupos vacíos)
              if (item.item_type === 'GROUP') {
                return hasVisibleChildren ? { ...item, children } : null;
              }

              // ITEM, DIVIDER, EXTERNAL_LINK: incluir si coincide la ubicación
              if (matchesLocation || hasVisibleChildren) {
                return { ...item, children };
              }

              return null;
            })
            .filter((i): i is MenuItem => i !== null);
        };

        const filtered = filterRecursive(menus);
        return this.sortMenus(filtered);
      })
    );
  }
  
  /**
   * Obtiene los menús de la barra de navegación (navbar)
   * @returns Observable<MenuItem[]>
   */
  getNavbarMenus(): Observable<MenuItem[]> {
    return this.getMenusByLocation('navbar');
  }
  
  /**
   * Obtiene los menús del dropdown de perfil (profile)
   * @returns Observable<MenuItem[]>
   */
  getProfileMenus(): Observable<MenuItem[]> {
    return this.getMenusByLocation('profile');
  }
  
  /**
   * Obtiene los menús de la barra lateral (sidebar)
   * @returns Observable<MenuItem[]>
   */
  getSidebarMenus(): Observable<MenuItem[]> {
    return this.getMenusByLocation('sidebar');
  }
  
  /**
   * Obtiene los menús del pie de página (footer)
   * @returns Observable<MenuItem[]>
   */
  getFooterMenus(): Observable<MenuItem[]> {
    return this.getMenusByLocation('footer');
  }
  
  /**
   * Ordena menús por order_index y sus hijos recursivamente
   * @param menus Array de menús
   * @returns Array ordenado
   */
  private sortMenus(menus: MenuItem[]): MenuItem[] {
    const sorted = [...menus].sort((a, b) => a.order_index - b.order_index);
    return sorted.map(menu => ({
      ...menu,
      children: menu.children ? this.sortMenus(menu.children) : []
    }));
  }
  
  /**
   * Construye el árbol jerárquico de menús (parent_id)
   * NOTA: El backend ya envía el árbol construido en el campo 'children'
   * Este método es por si se necesita construir localmente
   * @param flatMenus Array plano de menús
   * @returns Array con estructura de árbol
   */
  buildMenuTree(flatMenus: MenuItem[]): MenuItem[] {
    // El backend ya envía la estructura construida con children[]
    // Este método queda como utilidad por si se necesita en el futuro
    return flatMenus.filter(menu => !('parent_id' in menu));
  }
}
