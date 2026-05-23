import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { TranslocoLoader, Translation } from '@ngneat/transloco';
import { Observable } from 'rxjs';

/**
 * Loader that fetches translations from `assets/i18n/{lang}/{scope}.json`.
 * Supports the newer Transloco loader signature: getTranslation(lang, data?).
 */
@Injectable({ providedIn: 'root' })
export class TranslocoHttpLoader implements TranslocoLoader {
  constructor(private http: HttpClient) {}

  getTranslation(lang: string, data?: any): Observable<Translation> | Promise<Translation> {
    // `data` can be a string (scope) or an object containing scope information.
    let scope: string | undefined;
    if (typeof data === 'string') {
      scope = data;
    } else if (data && typeof data === 'object' && (data as any).scope) {
      scope = (data as any).scope;
    }

    const basePath = `/assets/i18n/${lang}`;
    const path = scope ? `${basePath}/${scope}.json` : `${basePath}/shared.json`;
    return this.http.get<Translation>(path);
  }
}
