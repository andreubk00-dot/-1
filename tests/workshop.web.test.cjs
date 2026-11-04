const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const {existsSync}=require('node:fs');
const base=process.env.GAME_URL||'http://127.0.0.1:8765';
const key='quiet-valley:v1:user://farm_v1.json';
const delay=ms=>new Promise(r=>setTimeout(r,ms));
let count=0;
function check(value,message){assert.ok(value,message);console.log('PASS:',message);count++;}
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),headless:true,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const page=await browser.newPage({viewport:{width:1280,height:720}});
 const errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 const state=()=>page.evaluate(k=>JSON.parse(localStorage.getItem(k)),key);
 const click=async(x,y)=>{await page.mouse.click(x,y);await delay(240);};
 const enter=async()=>{await page.locator('#play').waitFor({state:'visible',timeout:90000});await page.locator('#play').click();await delay(350);};
 // Fixtures arrange saved player positions; every transaction is executed by canvas input.
 await page.addInitScript(({key})=>{
  const next=sessionStorage.getItem('next-test-state');
  if(next){localStorage.setItem(key,next);sessionStorage.removeItem('next-test-state');}
  if(!localStorage.getItem(key))localStorage.setItem(key,JSON.stringify({version:1,player:[456,336],day:1,minutes:360,energy:100,coins:500,bag:{wood:100,stone:100,seeds:8,turnip:3},quest:5,plots:[],resources:[],buildings:[]}));
 },{key});
 const relocate=async(player)=>{
  const saved=await state();saved.player=player;
  await page.evaluate(s=>sessionStorage.setItem('next-test-state',JSON.stringify(s)),saved);
  await page.reload();await enter();
 };
 try{
  await page.goto(base);await enter();
  let saved=await state();
  check(saved.bag.planks===0&&saved.progression.tool_level===1,'legacy browser save gains production defaults');
  await page.keyboard.press('b');await delay(150);
  await click(640,402); // Workshop in construction catalog.
  await click(664,432); // Cell (19,15), clear ground next to player.
  saved=await state();
  check(saved.workshop[0]===19&&saved.workshop[1]===15&&saved.coins===440&&saved.bag.wood===60&&saved.bag.stone===80,'catalog places workshop and charges exact construction cost');
  await click(664,432);
  await click(400,400);await click(400,400); // Two boards orders.
  saved=await state();
  check(saved.progression.jobs.length===2&&saved.bag.wood===52,'recipe buttons enqueue and charge materials');
  await delay(500);
  check((await state()).progression.jobs[0].remaining===30,'production menu pauses work');
  await page.keyboard.press('Escape');await delay(180);await delay(650);await page.keyboard.press('F5');await delay(150);
  check((await state()).progression.jobs[0].remaining<30,'queued production advances in active gameplay');
  await relocate([252,252]);
  check((await state()).progression.jobs.length===2,'queued production survives browser reload');
  await click(504,312);await click(640,278); // Home -> sleep.
  saved=await state();
  check(saved.day===2&&saved.progression.jobs.length===0&&saved.progression.products.planks===4,'sleep completes queued production through real home dialog');
  await relocate([456,336]);await click(664,432);
  await page.screenshot({path:'tests/workshop-v2.png'});
  await click(640,478); // Collect.
  saved=await state();
  check(saved.bag.planks===4&&saved.progression.products.planks===0,'collection transfers workshop products exactly once');
  await click(415,181); // Tool upgrade menu.
  await page.screenshot({path:'tests/upgrade-v2.png'});
  await click(640,366); // Confirm upgrade.
  saved=await state();
  check(saved.progression.tool_level===2&&saved.coins===340&&saved.bag.planks===0&&saved.bag.stone===75,'tool upgrade applies and charges exact ingredients');
  await page.keyboard.press('Escape');await delay(180);await click(664,432);
  await click(400,400);await page.keyboard.press('Escape');await delay(180);
  await relocate([252,252]);await click(504,312);await click(640,278);
  await relocate([456,336]);await click(664,432);await click(640,478);
  check((await state()).bag.planks===2,'production remains usable after upgrade');
  await click(880,400); // Crate recipe.
  saved=await state();
  check(saved.bag.planks===0&&saved.bag.turnip===2&&saved.progression.jobs[0].recipe==='crate','crate recipe consumes boards and produce');
  await page.keyboard.press('Escape');await delay(180);await relocate([252,252]);await click(504,312);await click(640,278);
  await relocate([456,336]);await click(664,432);await click(640,478);
  check((await state()).bag.crate===1,'finished crate can be collected');
  await page.keyboard.press('Escape');await delay(180);await relocate([684,276]);
  await click(640,312); // Shop cell (28,10), directly in front of saved player.
  await page.screenshot({path:'tests/shop-v2.png'});
  await click(640,402); // Sell all produce.
  saved=await state();
  check(saved.bag.crate===0&&saved.bag.turnip===0&&saved.coins===530&&saved.progression.crates_sold===1,'shop sells two turnips and one crafted crate');
  check(errors.length===0,'no browser runtime errors: '+errors.join('\n'));
  console.log(`ALL ${count} WORKSHOP BROWSER CHECKS PASSED`);
 }catch(e){await page.screenshot({path:'tests/workshop-failure.png'});throw e;}
 finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
