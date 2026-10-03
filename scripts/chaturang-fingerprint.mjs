import {readdirSync,readFileSync,writeFileSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {join} from 'node:path';
function files(path){return readdirSync(path,{withFileTypes:true}).filter(e=>e.name!==".DS_Store").flatMap(e=>e.isDirectory()?files(join(path,e.name)):[join(path,e.name)]).sort()}
const hash=createHash('sha256');
for(const path of [...files('chaturang-game/lib'),...files('chaturang-game/web'),...files('chaturang-game/assets'),...files('chaturang-game/tool'),'chaturang-game/pubspec.yaml','chaturang-game/pubspec.lock'].sort()){hash.update(path);hash.update(readFileSync(path));}
const digest=hash.digest('hex'),out='public/chaturang-game/source-sha256.txt';
if(process.argv.includes('--write'))writeFileSync(out,digest+'\n');
else if(!existsSync(out)||readFileSync(out,'utf8').trim()!==digest){console.error('Chaturang web assets are missing or stale. Run npm run build:chaturang with Flutter installed, then include public/chaturang-game in the deployment.');process.exit(1)}
else console.log('Chaturang source matches the bundled web build.');
