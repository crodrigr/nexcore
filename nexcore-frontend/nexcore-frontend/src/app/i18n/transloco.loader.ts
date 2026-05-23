import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { TranslocoLoader } from '@ngneat/transloco';
import { Observable } from 'rxjs';

/**
 * Loader that fetches translations from `assets/i18n/{lang}/{scope}.json`.
 * If scope is not provided, it will try to load `assets/i18n/{lang}/shared.json`.
 */
@Injectable({ providedIn: 'root' })
export class TranslocoHttpLoader implements TranslocoLoader {
  constructor(private http: HttpClient) {}

  getTranslation(lang: string, scope?: string): Observable<Record<string, any>> {
    const basePath = `/assets/i18n/${lang}`;
    const path = scope ? `${basePath}/${scope}.json` : `${basePath}/shared.json`;
    return this.http.get<Record<string, any>>(path);
  }
}
