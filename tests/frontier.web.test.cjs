const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const{existsSync}=require('node:fs');
const base=process.env.GAME_URL||'http://127.0.0.1:8765',key='quiet-valley:v1:user://farm_v1.json';
const wait=ms=>new Promise(r=>setTimeout(r,ms));let count=0;
function check(value,message){assert.ok(value,message);console.log('PASS:',message);count++;}
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),headless:true,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const context=await browser.newContext({viewport:{width:1280,height:720}}),p=await context.newPage(),errors=[];
 p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 const enter=async()=>{await p.locator('#play').waitFor({state:'visible',timeout:90000});await p.locator('#play').click();await wait(350)};
 const read=async()=>{await p.keyboard.press('F5');await wait(160);return p.evaluate(k=>JSON.parse(localStorage.getItem(k)),key)};
 const click=async(x,y)=>{await p.mouse.click(x,y);await wait(250)};
 const relocate=async(player,overrides={})=>{const s=await read();Object.assign(s,overrides,{player});await p.evaluate(s=>sessionStorage.setItem('next-test-state',JSON.stringify(s)),s);await p.reload();await enter()};
 await p.addInitScript(({key})=>{
  const next=sessionStorage.getItem('next-test-state');if(next){localStorage.setItem(key,next);sessionStorage.removeItem('next-test-state')}
  if(!localStorage.getItem(key))localStorage.setItem(key,JSON.stringify({version:2,player:[456,336],day:1,minutes:600,energy:60,coins:500,bag:{wood:30,stone:30,seeds:8,turnip:2,berry:6,fish:0,ore:9},quest:5,plots:[[18,18,0,false,'turnip']],resources:[],buildings:[],workshop:[19,15],hotbar:['hand','hoe','water','seeds','axe','pick','rod','berry','',''],active_slot:0}));
 },{key});
 try{
  await p.goto(base);await enter();let s=await read();
  check(s.day===1&&s.bag.turnip===2&&s.plots[0][0]===18&&s.frontier.completed.length===0,'v0.4 farm migrates with original crops and new exploration defaults');
  check(s.resources.some(q=>q[0]>=48)&&s.inventory_layout.includes('rod')&&s.hotbar[6]==='rod','new regions receive resources and rod without replacing custom hotbar');
  await p.keyboard.press('g');await wait(220);const paused=(await read()).minutes;await wait(600);
  check((await read()).minutes===paused,'full world map pauses the simulation');await p.screenshot({path:'tests/world-map-rc1.png'});
  await p.keyboard.press('Escape');await wait(180);await click(664,432);await click(685,181);await p.screenshot({path:'tests/smelter-rc1.png'});
  // Smelter recipe button, below the ingredients and explanatory line.
  await click(640,350);await click(640,350);await click(640,350);s=await read();
  check(s.progression.jobs.length===3&&s.bag.ore===0&&s.bag.wood===27,'smelter enqueues three copper ingots and charges exact materials');
  await p.keyboard.press('Escape');await wait(150);await relocate([252,252]);await click(504,312);await click(640,278);
  check((await read()).progression.products.ingot===3,'overnight rest completes smelting jobs');
  await relocate([456,336]);await click(664,432);await click(640,478);
  check((await read()).bag.ingot===3,'workshop collects newly smelted copper');
  await p.keyboard.press('Escape');await wait(150);await relocate([1380,996]);await p.screenshot({path:'tests/quarry-rc1.png'});await click(640,312);await p.screenshot({path:'tests/villager-miner-rc1.png'});await click(640,405);s=await read();
  check(s.frontier.completed.includes('boris')&&s.bag.ingot===0&&s.coins===860,'quarry villager accepts copper and grants one-time reward');
  await click(640,405);check((await read()).coins===860,'completed villager request cannot pay twice');
  await p.keyboard.press('Escape');await wait(150);await relocate([1188,228],{energy:60});await p.keyboard.press('1');await click(640,312);s=await read();
  check(s.bag.berry===8&&s.frontier.picked.some(q=>q[0]===49&&q[1]===8),'hand gathers persistent berries in new forest');
  await wait(450);await click(640,312);check((await read()).bag.berry===8,'picked forest bush cannot be farmed repeatedly');
  await p.keyboard.press('8');await click(640,360);s=await read();
  check(s.bag.berry===7&&s.energy===68,'berries assigned to hotbar restore stamina and consume one item');
  await relocate([1188,300]);await p.keyboard.press('1');await p.screenshot({path:'tests/forest-rc1.png'});await click(640,312);await click(640,405);s=await read();
  check(s.frontier.completed.includes('lina')&&s.bag.berry===1&&s.coins===1020,'forester quest uses berries and persists its reward');
  await p.keyboard.press('Escape');await wait(150);await relocate([1404,468]);await p.keyboard.press('7');await click(688,360);await p.keyboard.press('e');s=await read();
  check(s.bag.fish===0&&s.frontier.catches===0,'reeling too early never creates fish');
  await wait(200);await click(688,360);await p.keyboard.press('g');await wait(2000);await p.keyboard.press('Escape');await wait(2100);await p.screenshot({path:'tests/fishing-rc1.png'});await p.keyboard.press('e');s=await read();
  check(s.bag.fish===1&&s.frontier.catches===1,'fishing bite timer pauses in map then resumes for successful catch');
  for(let i=0;i<2;i++){await click(688,360);await wait(2450);await p.keyboard.press('e');await wait(180)}
  s=await read();check(s.bag.fish===3&&s.frontier.catches===3,'successive timed casts award exactly one fish each');
  await relocate([1548,636]);await p.keyboard.press('1');await click(640,312);await p.screenshot({path:'tests/villager-fisher-rc1.png'});await click(640,405);s=await read();
  check(s.frontier.completed.length===3&&s.bag.fish===0&&s.coins===1260,'fisher quest completes all three distinct villagers');
  await p.keyboard.press('Escape');await wait(150);await relocate([456,336],{day:6});s=await read();
  check(s.plots.find(q=>q[0]===18&&q[1]===18)[3]===true,'rain automatically waters a growing crop');await p.screenshot({path:'tests/rain-rc1.png'});
  await relocate([252,252]);await click(504,312);await click(640,278);s=await read();
  check(s.day===7&&s.plots.find(q=>q[0]===18&&q[1]===18)[2]===1,'rain advances crop growth after overnight rest');
  await p.keyboard.press('m');check((await read()).muted===true,'audio preference is saved');
  await p.reload();await enter();s=await read();
  check(s.frontier.completed.length===3&&s.frontier.catches===3&&s.hotbar[6]==='rod'&&s.muted===true,'reload preserves villagers, catches, custom tools and audio setting');
  check(errors.length===0,'no expanded-world runtime errors: '+errors.join('\n'));
  await context.close();
  // Independent mobile fixture: cast and reel with real touch and the on-screen action button.
  const mobile=await browser.newContext({viewport:{width:960,height:540},isMobile:true,hasTouch:true}),m=await mobile.newPage(),mobileErrors=[];
  m.on('pageerror',e=>mobileErrors.push(e.message));m.on('console',msg=>{if(msg.type()==='error')mobileErrors.push(msg.text())});
  await m.addInitScript(({key})=>{if(!localStorage.getItem(key))localStorage.setItem(key,JSON.stringify({version:2,player:[1572,348],day:1,minutes:600,energy:100,coins:80,bag:{wood:0,stone:0,seeds:8,turnip:0},quest:0,plots:[],resources:[],buildings:[]}))},{key});
  await m.goto(base);await m.locator('#play').waitFor({state:'visible',timeout:90000});await m.locator('#play').click();await wait(300);await m.keyboard.press('F5');await wait(160);
  let ms=await m.evaluate(k=>JSON.parse(localStorage.getItem(k)),key),cell=ms.inventory_layout.indexOf('rod');
  await m.touchscreen.tap(914,168);await wait(150);await m.touchscreen.tap(146+62*(cell%6),165+60*Math.floor(cell/6));await m.touchscreen.tap(574,490);await m.touchscreen.tap(824,70);await wait(180);await m.touchscreen.tap(574,490);await m.locator('#action').tap();await wait(2700);await m.locator('#action').tap();await wait(250);
  ms=await m.evaluate(k=>JSON.parse(localStorage.getItem(k)),key);check(ms.bag.fish===1&&ms.frontier.catches===1,'mobile touch assigns rod, casts and reels with on-screen action');
  await m.screenshot({path:'tests/fishing-mobile-rc1.png'});await m.touchscreen.tap(560,35);await wait(200);check(!await m.locator('#touch').isVisible(),'mobile region header opens map without covering action button');await m.screenshot({path:'tests/map-mobile-rc1.png'});await m.touchscreen.tap(824,70);await wait(150);check(await m.locator('#touch').isVisible(),'closing mobile map restores action controls');check(mobileErrors.length===0,'no mobile fishing runtime errors');await mobile.close();
  console.log(`ALL ${count} FRONTIER BROWSER CHECKS PASSED`);
 }catch(e){await p.screenshot({path:'tests/frontier-failure.png'}).catch(()=>{});throw e}finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
