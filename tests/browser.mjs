import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import {mkdir} from 'node:fs/promises';

await mkdir('artifacts',{recursive:true});
const browser=await chromium.launch({channel:'msedge',headless:true,args:['--enable-webgl','--ignore-gpu-blocklist','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const base='http://127.0.0.1:8080';
const sdkMock=`window.sdkLog=[];window.sdkHandlers={};window.testAdCallbacks=null;window.YaGames={init:async()=>({environment:{i18n:{lang:new URLSearchParams(location.search).get('lang')||'ru'}},on:(key,cb)=>sdkHandlers[key]=cb,features:{LoadingAPI:{ready:()=>sdkLog.push('ready')},GameplayAPI:{start:()=>sdkLog.push('start'),stop:()=>sdkLog.push('stop')}},adv:{showFullscreenAdv:({callbacks})=>{testAdCallbacks=callbacks;sdkLog.push('ad');callbacks.onOpen();}},screen:{fullscreen:{request:async()=>{sdkLog.push('fullscreen');}}}})};`;
const errors=[];
async function open(context, query='') {
  const page=await context.newPage();
  // A software-rendered WebAssembly boot can take well over the 30s default.
  page.setDefaultTimeout(90000);
  page.on('pageerror',e=>{errors.push(e.message);console.log('PAGE_ERROR',e.message);});
  // Headless machines without an audio device report this; it is not a game fault.
  const audioDeviceNoise=/AudioContext encountered an error/;
  page.on('console',m=>{if(m.type()==='error'&&!audioDeviceNoise.test(m.text())){errors.push(m.text());console.log('CONSOLE_ERROR',m.text(),m.location());}});
  page.on('requestfailed',r=>console.log('REQUEST_FAILED',r.url(),r.failure()?.errorText));
  await page.route('**/sdk.js',route=>route.fulfill({contentType:'text/javascript',body:sdkMock}));
  await page.goto(base+query,{waitUntil:'load'});
  await page.waitForFunction(()=>window.sdkLog?.includes('ready'),{timeout:60000});
  await page.waitForTimeout(300);
  console.log('Loaded',await page.viewportSize());
  return page;
}
try {
  const context=await browser.newContext({viewport:{width:1280,height:800}});
  const page=await open(context);
  assert.deepEqual(await page.evaluate(()=>sdkLog),['ready']);
  await page.screenshot({path:'artifacts/menu-desktop.png'});
  await page.mouse.click(640,328);
  await page.waitForFunction(()=>sdkLog.includes('start'));
  await page.waitForTimeout(2200);
  await page.screenshot({path:'artifacts/gameplay-desktop.png'});
  console.log('Desktop gameplay');
  // Open the Parts category, spawn a crate, then freeze it through the toolbar.
  await page.mouse.click(85,118);
  await page.waitForTimeout(200);
  await page.mouse.click(61,198);
  await page.mouse.click(490,420);
  await page.keyboard.press('Digit4');
  await page.mouse.click(490,440);
  await page.keyboard.press('Space');
  assert.equal(await page.evaluate(()=>sdkLog.at(-1)),'stop');
  await page.keyboard.press('Space');
  assert.equal(await page.evaluate(()=>sdkLog.at(-1)),'start');
  // SDK pause blocks actual gameplay and user input, then resumes normally.
  await page.evaluate(()=>sdkHandlers.game_api_pause());
  await page.waitForTimeout(100);
  assert.equal(await page.evaluate(()=>KineticBridge.state().paused),true);
  assert.equal(await page.evaluate(()=>sdkLog.at(-1)),'stop');
  await page.evaluate(()=>sdkHandlers.game_api_resume());
  await page.waitForTimeout(100);
  assert.equal(await page.evaluate(()=>sdkLog.at(-1)),'start');
  await page.mouse.click(58,739);
  const stored=await page.evaluate(()=>JSON.parse(localStorage.getItem('kinetic_lab_v1')));
  assert.ok(stored.scene.entities.length>=8,'Spawned object and scene saved');
  assert.ok(stored.stats.spawn>=1);
  await page.waitForTimeout(1000);
  await page.reload();
  await page.waitForFunction(()=>window.sdkLog?.includes('ready'));
  await page.mouse.click(640,328);
  await page.waitForFunction(()=>sdkLog.includes('start'));
  // Resize both narrower and wider than the desktop design.
  await page.setViewportSize({width:1024,height:768});
  await page.waitForTimeout(500);
  await page.screenshot({path:'artifacts/desktop-1024.png'});
  await page.setViewportSize({width:1920,height:800});
  await page.waitForTimeout(500);
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);
  assert.equal(await page.evaluate(()=>document.querySelector('canvas').width<=1600*devicePixelRatio),true);
  await page.screenshot({path:'artifacts/desktop-ultrawide.png'});
  await context.close();
  console.log('Desktop complete');
  // The portal reports the locale; every language other than Russian gets English.
  const enContext=await browser.newContext({viewport:{width:1280,height:800}});
  const en=await open(enContext,'?lang=en');
  assert.equal(await en.evaluate(()=>document.documentElement.lang),'en');
  assert.equal(await en.evaluate(()=>document.getElementById('loading-label').textContent),'Preparing the laboratory');
  await en.screenshot({path:'artifacts/menu-english.png'});
  await en.mouse.click(640,328);
  await en.waitForFunction(()=>sdkLog.includes('start'));
  await en.waitForTimeout(2200);
  await en.screenshot({path:'artifacts/gameplay-english.png'});
  // The in-game RU/EN button overrides the portal locale and survives a reload.
  await en.mouse.click(1165,33);
  await en.waitForTimeout(600);
  assert.equal(await en.evaluate(()=>JSON.parse(localStorage.getItem('kinetic_lab_v1')||'{}').lang),'ru','Language choice is stored');
  await en.reload();
  await en.waitForFunction(()=>window.sdkLog?.includes('ready'));
  assert.equal(await en.evaluate(()=>document.documentElement.lang),'ru','Stored language wins over the portal locale');
  await enContext.close();
  console.log('English complete');
  const mobileContext=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:1,isMobile:true,hasTouch:true});
  const phone=await open(mobileContext);
  await phone.screenshot({path:'artifacts/menu-mobile.png'});
  // The mobile canvas uses an expanded 854x480 logical viewport.
  const canvas=await phone.locator('canvas').boundingBox();
  const scale=canvas.height/480;
  await phone.touchscreen.tap(canvas.x+canvas.width/2,canvas.y+175*scale);
  await phone.waitForFunction(()=>sdkLog.includes('start'));
  await phone.waitForTimeout(1500);
  await phone.screenshot({path:'artifacts/gameplay-mobile.png'});
  await phone.setViewportSize({width:390,height:844});
  await phone.waitForTimeout(300);
  assert.equal(await phone.locator('#rotate').isVisible(),true);
  assert.equal(await phone.evaluate(()=>KineticBridge.state().paused),true);
  await phone.screenshot({path:'artifacts/portrait.png'});
  await phone.setViewportSize({width:844,height:390});
  await phone.waitForTimeout(300);
  assert.equal(await phone.evaluate(()=>KineticBridge.state().paused),false);
  await mobileContext.close();
  assert.deepEqual(errors,[],'No JavaScript or Godot runtime errors');
  console.log('BROWSER_TEST_OK desktop touch storage reload resize sdk_pause orientation');
} finally {await browser.close();}
