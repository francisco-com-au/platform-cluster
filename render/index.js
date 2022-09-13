// Imports
const fs = require('fs');

// Render
const platformApps = require('./modules/platform-apps');

const apps_repo = process.env.APPS_REPO || "francisco-com-au/platform-apps";
const APP_ENV = process.env.APP_ENV || 'main';
const PLATFORM_ENV = process.env.PLATFORM_ENV || "main";

const rendered = platformApps(apps_repo, PLATFORM_ENV, APP_ENV);

fs.writeFileSync('applicationSet.yaml', rendered);
