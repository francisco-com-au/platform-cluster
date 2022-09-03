// Imports
const fs = require('fs');

// Render
const platformApps = require('./modules/platform-apps');

const apps_repo = process.env.APPS_REPO || "francisco-com-au/platform-apps";
const branch = "main";
const env = process.env.ENVIRONMENT || 'main';

const rendered = platformApps(apps_repo, branch, env);

fs.writeFileSync('applicationSet.yaml', rendered);
