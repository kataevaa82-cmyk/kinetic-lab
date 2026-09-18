const test = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname,'../web/bridge.js'),'utf8');

function setup({language='ru', failInit=false, failStorage=false}={}) {
  const events = new Map();
  const sdkEvents = new Map();
  const log = [];
  const storage = new Map();
  let callbacks;
  const sdk = {
    environment:{i18n:{lang:language}},
    features:{LoadingAPI:{ready:()=>log.push('ready')},GameplayAPI:{start:()=>log.push('start'),stop:()=>log.push('stop')}},
    on:(id,callback)=>sdkEvents.set(id,callback),
    adv:{showFullscreenAdv:args=>{callbacks=args.callbacks;log.push('ad');}},
    screen:{fullscreen:{request:()=>Promise.resolve()}}
  };
  const context = {
    navigator:{language:'ru-RU',userAgent:'test'},
    matchMedia:()=>({matches:false}),
    innerWidth:1280,innerHeight:800,
    document:{hidden:false,documentElement:{lang:'ru',classList:{toggle(){}}},getElementById:()=>null,addEventListener:(key,fn)=>events.set(key,fn)},
    addEventListener:(key,fn)=>events.set(key,fn),
    localStorage:{getItem:key=>{if(failStorage) throw Error('blocked');return storage.get(key);},setItem:(key,v)=>{if(failStorage) throw Error('quota');storage.set(key,v);}},
    YaGames:{init:async()=>{if(failInit)throw Error('offline');return sdk;}}
  };
  context.window=context;
  vm.runInNewContext(source,context);
  const bridge=context.KineticBridge;
  return {bridge,events,sdkEvents,log,context,get callbacks(){return callbacks;}};
}

test('Game Ready waits for engine, visible UI and SDK, and runs once',async()=>{
  const f=setup();
  f.bridge.gameReady();
  await f.bridge.init();
  assert.deepEqual(f.log,[]);
  f.bridge.loaderHidden();
  f.bridge.gameReady();
  f.bridge.loaderHidden();
  assert.deepEqual(f.log,['ready']);
  f.bridge.gameplay(true);
  f.bridge.gameplay(true);
  assert.deepEqual(f.log,['ready','start']);
});
test('Delayed SDK init preserves readiness and selects SDK language',async()=>{
  const f=setup({language:'en'});
  f.bridge.gameReady();f.bridge.loaderHidden();f.bridge.gameplay(true);
  await f.bridge.init();
  assert.equal(f.bridge.state().language,'en');
  assert.deepEqual(f.log,['ready','start']);
});
test('Independent pause causes cannot resume each other; manual menu remains stopped',async()=>{
  const f=setup();await f.bridge.init();f.bridge.gameReady();f.bridge.loaderHidden();f.bridge.gameplay(true);
  f.events.get('blur')();
  f.sdkEvents.get('game_api_pause')();
  f.events.get('focus')();
  assert.equal(f.bridge.state().paused,true);
  f.bridge.gameplay(false);
  f.sdkEvents.get('game_api_resume')();
  assert.equal(f.bridge.state().paused,false);
  assert.equal(f.log.at(-1),'stop');
  f.bridge.gameplay(true);
  assert.equal(f.log.at(-1),'start');
});
test('Ad freezes gameplay, closes once and does not clear hidden-tab pause',async()=>{
  const f=setup();await f.bridge.init();f.bridge.gameReady();f.bridge.loaderHidden();f.bridge.gameplay(true);
  let closed=0;
  f.bridge.subscribe(json=>{if(JSON.parse(json).event==='ad_closed')closed++;});
  f.bridge.interstitial();
  assert.equal(f.bridge.state().paused,true);
  f.context.document.hidden=true;
  f.events.get('visibilitychange')();
  f.callbacks.onOpen();
  f.callbacks.onClose(true);
  f.callbacks.onError({});
  assert.equal(closed,1);
  assert.equal(f.bridge.state().paused,true);
  f.context.document.hidden=false;
  f.events.get('visibilitychange')();
  assert.equal(f.bridge.state().paused,false);
  assert.equal(f.log.at(-1),'start');
});
test('Ads rejected by SDK leave the game usable',async()=>{
  const f=setup();await f.bridge.init();f.bridge.gameReady();f.bridge.loaderHidden();
  f.bridge.interstitial();f.callbacks.onError({});
  assert.equal(f.bridge.state().paused,false);
});
test('Guest storage round trips; blocked storage and SDK failure are handled',async()=>{
  const f=setup();assert.equal(f.bridge.save('{"version":1}'),true);assert.equal(f.bridge.load(),'{"version":1}');
  const offline=setup({failInit:true,failStorage:true});await offline.bridge.init();
  assert.equal(offline.bridge.load(),'');assert.equal(offline.bridge.save('{}'),false);
  let done=false;offline.bridge.subscribe(j=>{if(JSON.parse(j).event==='ad_closed')done=true;});
  offline.bridge.interstitial();assert.equal(done,true);
});
