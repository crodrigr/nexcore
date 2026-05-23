import { ApplicationConfig, provideBrowserGlobalErrorListeners, provideZoneChangeDetection, importProvidersFrom } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';

// Transloco (i18n) - runtime, lazy-load
import { provideTransloco } from '@ngneat/transloco';
import { translocoConfig } from '@ngneat/transloco';
import { TranslocoHttpLoader } from './i18n/transloco.loader';

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
  ]
};
