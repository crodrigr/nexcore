import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { tap, catchError, map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

export interface User {
  iduser: string;
  username: string;
  name: string;
  email: string;
  phone: string | null;
  photo: string | null;
  roles: string[];
}

export interface MenuItem {
  id: string;
  name: string;
  title: string;
  icon?: string;
  icon_type?: string;
  route: string | null;
  location: string;
  item_type: 'ITEM' | 'GROUP' | 'DIVIDER' | 'EXTERNAL_LINK';
  access: 'execute' | 'view' | 'hidden';
  order_index: number;
  children: MenuItem[];
}

export type AccessLevel = 'execute' | 'view' | 'hidden';

export interface PermissionElement {
  element_key: string;
  access: AccessLevel;
}

export interface Permission {
  component: string;
  route: string;
  access: AccessLevel;
  elements: PermissionElement[];
}

export interface Profile {
  user: User;
  menus: MenuItem[];
  permissions: Permission[];
  token: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class ProfileService {
  
  private readonly PROFILE_KEY = 'profile';
  private readonly profileUrl = `${environment.coreBaseUrl}/api/v1/me/profile`;
  
  // Subjects privados
  private readonly userSubject = new BehaviorSubject<User | null>(null);
  private readonly menusSubject = new BehaviorSubject<MenuItem[]>([]);
  private readonly permissionsSubject = new BehaviorSubject<Permission[]>([]);
  
  // Observables públicos
  public user$ = this.userSubject.asObservable();
  public menus$ = this.menusSubject.asObservable();
  public permissions$ = this.permissionsSubject.asObservable();
  
  constructor(private readonly http: HttpClient) {
    this.loadFromStorage();
  }
  
  /**
   * Carga el perfil desde el servidor
   */
  loadProfile(): Observable<Profile | null> {
    return this.http.get<Profile>(this.profileUrl).pipe(
      tap(profile => this.setProfile(profile)),
      catchError(error => {
        console.error('Error loading profile:', error);
        // If there's a stored profile in localStorage, restore and return it
        try {
          const stored = localStorage.getItem(this.PROFILE_KEY);
          if (stored) {
            const parsed: Profile = JSON.parse(stored);
            this.setProfile(parsed);
            console.warn('ProfileService: restored profile from localStorage fallback');
            return of(parsed);
          }
        } catch (e) {
          console.warn('ProfileService: failed to parse stored profile', e);
        }

        return of(null);
      })
    );
  }
  
  /**
   * Guarda el perfil en memoria y localStorage
   */
  setProfile(profile: Profile): void {
    if (!profile) return;
    const normalizedProfile = this.normalizeProfile(profile);
    
    this.userSubject.next(normalizedProfile.user);
    this.menusSubject.next(normalizedProfile.menus);
    this.permissionsSubject.next(normalizedProfile.permissions);
    
    // Guardar en localStorage
    localStorage.setItem(this.PROFILE_KEY, JSON.stringify(normalizedProfile));
  }
  
  /**
   * Carga el perfil desde localStorage al iniciar
   */
  private loadFromStorage(): void {
    const stored = localStorage.getItem(this.PROFILE_KEY);
    if (stored) {
      try {
        const profile: Profile = this.normalizeProfile(JSON.parse(stored));
        this.userSubject.next(profile.user);
        this.menusSubject.next(profile.menus);
        this.permissionsSubject.next(profile.permissions);
      } catch (error) {
        console.error('Error parsing profile from localStorage:', error);
        this.clearProfile();
      }
    }
  }
  
  /**
   * Limpia el perfil
   */
  clearProfile(): void {
    this.userSubject.next(null);
    this.menusSubject.next([]);
    this.permissionsSubject.next([]);
    localStorage.removeItem(this.PROFILE_KEY);
  }
  
  /**
   * Obtiene los menús filtrados por ubicación
   */
  getMenusByLocation(location: string): Observable<MenuItem[]> {
    return this.menus$.pipe(
      map(menus => menus.filter(menu => menu.location === location))
    );
  }
  
  /**
   * Obtiene el usuario actual
   */
  getCurrentUser(): User | null {
    return this.userSubject.value;
  }
  
  /**
   * Verifica si el usuario tiene un rol específico
   */
  hasRole(roleName: string): boolean {
    const user = this.userSubject.value;
    return user?.roles?.includes(roleName) ?? false;
  }
  
  /**
   * Obtiene las iniciales del usuario para el avatar
   */
  getUserInitials(): string {
    const user = this.userSubject.value;
    if (!user) return 'NC';
    
    const nameParts = user.name.split(' ');
    if (nameParts.length >= 2) {
      return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    }
    return user.name.substring(0, 2).toUpperCase();
  }

  private normalizeProfile(profile: Profile): Profile {
    return {
      ...profile,
      menus: this.normalizeMenus(profile.menus),
      permissions: profile.permissions ?? [],
    };
  }

  private normalizeMenus(menus: MenuItem[]): MenuItem[] {
    return (menus ?? []).map(menu => ({
      ...menu,
      location: menu.location === 'navbar' ? 'sidebar' : menu.location,
      children: menu.children ? this.normalizeMenus(menu.children) : []
    }));
  }
}
