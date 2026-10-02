import {readdirSync,readFileSync,writeFileSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {join} from 'node:path';
function files(path){return readdirSync(path,{withFileTypes:true}).flatMap(e=>e.isDirectory()?files(join(path,e.name)):[join(path,e.name)]).sort()}
const hash=createHash('sha256');
for(const path of [...files('web-game/lib'),...files('web-game/web'),...files('web-game/assets'),...files('web-game/branding'),'web-game/pubspec.yaml','web-game/pubspec.lock'].sort()){hash.update(path);hash.update(readFileSync(path));}
const digest=hash.digest('hex'),out='public/classic-game/source-sha256.txt';
if(process.argv.includes('--write'))writeFileSync(out,digest+'\n');
else if(!existsSync(out)||readFileSync(out,'utf8').trim()!==digest){console.error('Classic web assets are missing or stale. Run npm run build:classic with Flutter installed, then include public/classic-game in the deployment.');process.exit(1)}
else console.log('Classic source matches the bundled web build.');
