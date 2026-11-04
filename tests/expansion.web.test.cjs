const{chromium}=require('playwright');const assert=require('node:assert/strict');const{existsSync}=require('node:fs');
const base=process.env.GAME_URL||'http://127.0.0.1:8765',key='quiet-valley:v1:user://farm_v1.json';
const wait=ms=>new Promise(r=>setTimeout(r,ms));let checks=0;
function check(v,msg){assert.ok(v,msg);console.log('PASS:',msg);checks++;}
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),headless:true,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const p=await browser.newPage({viewport:{width:1280,height:720}}),errors=[];p.on('pageerror',e=>errors.push(e.message));p.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 const read=async()=>{await p.keyboard.press('F5');await wait(150);return p.evaluate(k=>JSON.parse(localStorage.getItem(k)),key);};
 const click=async(x,y)=>{await p.mouse.click(x,y);await wait(250);};
 const enter=async()=>{await p.locator('#play').waitFor({state:'visible',timeout:90000});await p.locator('#play').click();await wait(350);};
 const relocate=async(pos)=>{const s=await read();s.player=pos;await p.evaluate(s=>sessionStorage.setItem('next-test-state',JSON.stringify(s)),s);await p.reload();await enter();};
 await p.addInitScript(({key})=>{
  const next=sessionStorage.getItem('next-test-state');if(next){localStorage.setItem(key,next);sessionStorage.removeItem('next-test-state');}
  if(!localStorage.getItem(key)){const layout=Array(24).fill('');['hand','hoe','water','axe','pick','build','wood','seeds'].forEach((id,i)=>layout[i]=id);
   localStorage.setItem(key,JSON.stringify({version:1,player:[456,336],day:7,minutes:360,energy:100,coins:500,bag:{wood:100,stone:100,seeds:8,turnip:5},quest:5,plots:[[18,16,0,true]],resources:[],buildings:[],hotbar:['hand','hoe','water','seeds','axe','pick','build','','axe',''],active_slot:0,inventory_layout:layout}));}
 },{key});
 try{
  await p.goto(base);await enter();let s=await read();
  check(!s.hotbar.includes('build')&&!s.inventory_layout.includes('build')&&s.hotbar[8]==='axe'&&s.day===7,'v0.3 construction shortcuts migrate without resetting farm or other slots');
  await p.keyboard.press('i');await wait(200);await p.screenshot({path:'tests/inventory-v4.png'});
  await click(860,95);await wait(200);await p.screenshot({path:'tests/construction-v4.png'});
  const previous=JSON.stringify(s.hotbar);
  await click(640,402); // Workshop catalog card.
  const during=await read();check(JSON.stringify(during.hotbar)===previous&&during.active_slot===0,'construction tab enters placement without equipping a hotbar item');
  await p.keyboard.press("i");await wait(200);await p.keyboard.press("Escape");await wait(180);await click(664,432);
  check((await read()).workshop===null,"opening inventory cancels placement without building behind the window");
  await p.keyboard.press("b");await wait(150);await click(640,402);
  await p.mouse.move(664,432);await wait(100);await p.screenshot({path:'tests/placement-v4.png'});
  await p.mouse.click(664,432,{button:'right'});await wait(150);await click(664,432);s=await read();
  check(s.workshop===null&&s.bag.wood===100,'right-click cancels building without cost or placement');
  await p.keyboard.press('b');await wait(150);await click(640,402);await click(664,432);s=await read();
  check(s.workshop?.[0]===19&&s.coins===440&&s.bag.wood===60&&s.hotbar[6]==='','building works through dedicated tab with empty seventh hotbar slot');
  await relocate([684,276]);await click(640,312);await p.screenshot({path:'tests/shop-v4.png'});
  await click(880,254);s=await read();check(s.coins===410&&s.bag.carrot_seeds===5,'shop sells carrot seeds at the quoted price');
  await p.keyboard.press('Escape');await wait(180);await p.keyboard.press('j');await wait(200);await p.screenshot({path:'tests/orders-v4.png'});
  // First order card: its requirement row adds 30px above the submit button.
  await click(640,295);s=await read();check(s.orders.completed===1&&s.bag.turnip===0&&s.coins===620,'order hand-in charges five turnips and pays reward at shop');
  await p.keyboard.press('Escape');await wait(180);await relocate([456,408]);
  await p.keyboard.press('i');await wait(180);
  // Inventory insertion preserves old cells; carrot seeds occupy the vacated blueprint cell (5).
  const inv=await read(), seedCell=inv.inventory_layout.indexOf("carrot_seeds");
  check(seedCell>=0,"new seeds appear in the actual inventory");
  await click((146+62*(seedCell%6))*4/3,(165+60*Math.floor(seedCell/6))*4/3);await click(765,654);await p.keyboard.press('Escape');await wait(180);
  await p.keyboard.press('2');await click(712,432);await wait(500); // Soil cell (20,18).
  await p.keyboard.press('7');await click(712,432);await wait(500);s=await read();
  check(s.hotbar[6]==='carrot_seeds'&&s.plots.some(q=>q[0]===20&&q[1]===18&&q[4]==='carrot')&&s.bag.carrot_seeds===4,'new crop can be assigned to freed hotbar slot and planted');
  for(let day=0;day<4;day++){
   await p.keyboard.press('3');await click(712,432);await wait(650);await relocate([252,252]);await click(504,312);await click(640,278);await relocate([456,408]);
  }
  s=await read();check(s.plots.find(q=>q[0]===20&&q[1]===18)[2]===4,'carrot grows for four watered days through home rest');
  await p.keyboard.press('1');await click(712,432);await wait(450);s=await read();check(s.bag.carrot===1,'mature carrot can be harvested with free hand');
  await p.screenshot({path:'tests/farm-v4.png'});
  await p.reload();await enter();s=await read();check(s.orders.completed===1&&s.bag.carrot===1&&s.hotbar[6]==='carrot_seeds','new crops, orders and custom hotbar survive reload');
  check(errors.length===0,'no expansion runtime errors: '+errors.join('\n'));
  console.log(`ALL ${checks} EXPANSION BROWSER CHECKS PASSED`);
 }catch(e){await p.screenshot({path:'tests/expansion-failure.png'});throw e;}
 finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
