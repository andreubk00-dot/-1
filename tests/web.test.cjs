const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const { existsSync } = require('node:fs');
const base = process.env.GAME_URL || 'http://127.0.0.1:8765';
const slot = 'quiet-valley:v1:user://farm_v1.json';
let checks = 0;
function check(value, message) { assert.ok(value, message); console.log('PASS:', message); checks++; }
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function save(page) {
  await page.keyboard.press('F5'); await delay(150);
  return page.evaluate(key => JSON.parse(localStorage.getItem(key)), slot);
}
async function enter(page, suffix = '') {
  await page.goto(base + '/' + suffix);
  await page.locator('#play').waitFor({ state: 'visible', timeout: 90000 });
  await page.locator('#play').click(); await delay(350);
}
async function cellPoint(page, cell, state) {
  const box = await page.locator('#stage').boundingBox();
  const cx = Math.max(320, Math.min(832, state.player[0]));
  const cy = Math.max(180, Math.min(684, state.player[1]));
  return { x: box.x + (cell[0] * 24 + 12 - cx + 320) * box.width / 640,
    y: box.y + (cell[1] * 24 + 12 - cy + 180) * box.height / 360 };
}
async function act(page, tool, cell) {
  const state = await save(page);
  const point = await cellPoint(page, cell, state);
  await page.keyboard.press(String(tool));
  await page.mouse.click(point.x, point.y); await delay(250);
  return save(page);
}
(async () => {
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || (existsSync('/usr/bin/chromium') ? '/usr/bin/chromium' : undefined),
    headless: true,
    args: ['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader']
  });
  try {
    const errors = [];
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    const page = await context.newPage();
    page.on('pageerror', e => errors.push(e.message));
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    await enter(page);
    check(!await page.evaluate(() => ValleyPlatform.paused), 'standalone browser starts without SDK');
    let state = await act(page, 2, [19, 15]);
    check(state.plots.length === 1 && state.energy === 98, 'actual canvas input tills soil');
    state = await act(page, 4, [19, 15]);
    check(state.plots[0][2] === 0 && state.bag.seeds === 7, 'rapid tool switch followed by click plants the selected seed');
    state = await act(page, 3, [19, 15]);
    check(state.plots[0][3] && state.energy === 94, 'browser watering is saved');
    await page.evaluate(() => window.dispatchEvent(new Event('blur')));
    const pausedTime = await page.evaluate(key => JSON.parse(localStorage.getItem(key)).minutes, slot);
    await delay(600);
    check(await page.evaluate(() => ValleyPlatform.paused), 'blur pauses browser game');
    check(await page.evaluate(key => JSON.parse(localStorage.getItem(key)).minutes, slot) === pausedTime, 'time does not advance on pause');
    await page.evaluate(() => window.dispatchEvent(new Event('focus')));
    await delay(500);
    state = await save(page);
    check(state.minutes > pausedTime, 'focus resumes simulation');
    await enter(page);
    state = await save(page);
    check(state.bag.seeds === 7 && state.plots[0][3] && state.energy === 94, 'reload restores real gameplay progress');
    await page.screenshot({ path: 'tests/web-game.png' });
    await page.setViewportSize({width: 960, height: 700});
    await delay(300);
    check(await page.locator('canvas').evaluate(e => e.width >= 960), 'canvas resizes without a fixed small backing buffer');
    check(errors.length === 0, 'no runtime JavaScript/Godot errors: ' + errors.join('\n'));
    await context.close();

    const yc = await browser.newContext({ viewport: { width:1280, height:720 } });
    const yp = await yc.newPage();
    await yp.route('**/sdk.js', route => route.fulfill({ contentType: 'application/javascript', body: `
      window.sdkEvents=[]; window.sdkHandlers={};
      window.YaGames={init:async()=>({
        features:{LoadingAPI:{ready(){sdkEvents.push('ready')}},GameplayAPI:{start(){sdkEvents.push('start')},stop(){sdkEvents.push('stop')}}},
        on(name,callback){sdkHandlers[name]=callback}
      })};` }));
    await enter(yp, '?platform=yandex');
    check(await yp.evaluate(() => sdkEvents.filter(x => x === 'ready').length) === 1, 'SDK LoadingAPI.ready called once after engine readiness');
    check(await yp.evaluate(() => sdkEvents.includes('start')), 'SDK gameplay begins after player starts');
    await yp.keyboard.press('h'); await delay(200);
    check(await yp.evaluate(() => sdkEvents.at(-1) === 'stop'), 'gameplay stops in help menu');
    await yp.keyboard.press('Escape'); await delay(200);
    check(await yp.evaluate(() => sdkEvents.at(-1) === 'start'), 'gameplay resumes after menu');
    await yp.evaluate(() => sdkHandlers.game_api_pause()); await delay(250);
    check(await yp.evaluate(() => ValleyPlatform.paused && sdkEvents.at(-1) === 'stop'), 'SDK pause stops game and gameplay tracking');
    await yp.mouse.click(1219,305);await delay(180);
    check(!await yp.locator('#touch').evaluate(e=>e.hidden), 'SDK pause blocks HUD window buttons');
    await yp.dispatchEvent('#action','pointerdown');
    check(await yp.evaluate(()=>ValleyPlatform.takeAction()===false), 'SDK pause cannot queue a virtual action for later');
    state = await act(yp, 2, [19,15]);
    check(state.plots.length === 0, 'SDK pause blocks gameplay input');
    await yp.evaluate(() => sdkHandlers.game_api_resume()); await delay(200);
    state = await act(yp, 2, [19,15]);
    check(state.plots.length === 1, 'SDK resume restores interaction');
    await yc.close();

    const mc = await browser.newContext({ viewport: { width:960, height:540 }, isMobile:true, hasTouch:true });
    const mp = await mc.newPage();
    await enter(mp);
    check(await mp.locator('#touch').isVisible(), 'touch controls visible on mobile');
    state = await save(mp);
    const oldX = state.player[0];
    const cdp = await mc.newCDPSession(mp);
    const right = await mp.locator('#right').boundingBox();
    await cdp.send('Input.dispatchTouchEvent', {type:'touchStart', touchPoints:[{x:right.x+20,y:right.y+20,id:1}]});
    await delay(400);
    await cdp.send('Input.dispatchTouchEvent', {type:'touchEnd',touchPoints:[]});
    state = await save(mp);
    check(state.player[0] > oldX + 8, 'real touch moves the player');
    check(await mp.evaluate(() => ValleyPlatform.x === 0 && ValleyPlatform.y === 0), 'touch release clears movement');
    await mp.touchscreen.tap(249, 490);
    await delay(250);
    const action = await mp.locator('#action').boundingBox();
    await mp.touchscreen.tap(action.x + 25, action.y + 25);
    await delay(250);
    state = await save(mp);
    check(state.plots.length === 1, 'touch toolbar and action button perform gameplay');
    const up = await mp.locator('#up').boundingBox();
    await cdp.send('Input.dispatchTouchEvent', {type:'touchStart', touchPoints:[{x:up.x+20,y:up.y+20,id:2}]});
    await delay(100);
    await cdp.send('Input.dispatchTouchEvent', {type:'touchCancel',touchPoints:[]});
    check(await mp.evaluate(() => ValleyPlatform.x === 0 && ValleyPlatform.y === 0), 'cancelled touch cannot leave movement stuck');
    await mp.screenshot({path:'tests/web-mobile.png'});
    await mc.close();
    const blocked = await browser.newContext();
    await blocked.addInitScript(() => { Storage.prototype.setItem = function() { throw new DOMException('blocked', 'QuotaExceededError'); }; });
    const bp = await blocked.newPage();
    const blockedErrors = [];
    bp.on('pageerror', e => blockedErrors.push(e.message));
    await enter(bp);
    check(await bp.evaluate(() => ValleyPlatform.save('test', '{}') === false), 'blocked storage reports failure');
    check(blockedErrors.length === 0 && !await bp.evaluate(() => ValleyPlatform.paused), 'blocked storage does not crash or stop the game');
    await blocked.close();
    const failure = await browser.newContext();
    const fp = await failure.newPage();
    await fp.route('**/sdk.js', route => route.fulfill({contentType:'application/javascript',body:'window.YaGames={init:async()=>{throw new Error("SDK unavailable")}};'}));
    await fp.goto(base + '/?platform=yandex');
    await fp.locator('#retry').waitFor({state:'visible',timeout:10000});
    check((await fp.locator('#status').textContent()).includes('SDK unavailable'), 'SDK failure displays actionable retry screen');
    await failure.close();
    console.log(`ALL ${checks} BROWSER CHECKS PASSED`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
