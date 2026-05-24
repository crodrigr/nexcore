import { ApplicationConfig, provideBrowserGlobalErrorListeners, provideZoneChangeDetection, importProvidersFrom, APP_INITIALIZER } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { AuthInterceptor } from './shared/interceptors/auth.interceptor';

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
    provideHttpClient(withInterceptorsFromDi()),
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

// Register the AuthInterceptor so it is picked up by withInterceptorsFromDi()
export const httpInterceptorProviders = [
  { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true }
];

// add interceptor provider to the global providers so the DI picks it up
(appConfig.providers as any[]).push(...httpInterceptorProviders);
