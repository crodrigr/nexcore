import { bootstrapApplication } from '@angular/platform-browser';
// Load JIT compiler when needed (development fallback). Remove for production/AOT builds.
import '@angular/compiler';
import { appConfig } from './app/app.config';
import { App } from './app/app';

bootstrapApplication(App, appConfig)
  .catch((err) => console.error(err));
