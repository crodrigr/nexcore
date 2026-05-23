import { ApplicationConfig, provideBrowserGlobalErrorListeners, provideZoneChangeDetection, importProvidersFrom, APP_INITIALIZER } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';

// Transloco (i18n) - runtime, lazy-load
import { provideTransloco } from '@ngneat/transloco';
import { translocoConfig } from '@ngneat/transloco';
import { TranslocoHttpLoader } from './i18n/transloco.loader';
import { TranslocoService } from '@ngneat/transloco';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    // Http client required by Transloco loader
    provideHttpClient(),
    // Transloco provider: runtime translations, default en, fallback en
    provideTransloco({
      loader: TranslocoHttpLoader,
      config: translocoConfig({
        availableLangs: ['en', 'es'],
        defaultLang: 'en',
        fallbackLang: 'en',
        reRenderOnLangChange: true,
        prodMode: false
      })
    })
    ,
    // Ensure translations are loaded before the app bootstraps
    {
      provide: APP_INITIALIZER,
      useFactory: (transloco: TranslocoService) => {
        return () => {
          try {
            const saved = (localStorage.getItem('nexcore-lang') || 'en') as string;
            return transloco.load(saved).toPromise().then(() => transloco.setActiveLang(saved));
          } catch (e) {
            // If localStorage is unavailable, fallback to default language
            return transloco.load('en').toPromise().then(() => transloco.setActiveLang('en'));
          }
        };
      },
      deps: [TranslocoService],
      multi: true
    }
  ]
};
