import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
const source=readFileSync(new URL('../assets/xeris_provider.js',import.meta.url),'utf8');
function fixture({frame=false,protocol='https:',native=true,foreignSolana=null}={}){
  const messages=[],timers=new Map(),events=new Map();let next=0;
  const window={location:{protocol},crypto:{getRandomValues(bytes){bytes.fill(7);return bytes;}},addEventListener(name,fn){events.set(name,fn);},dispatchEvent(){}};
  window.top=frame?{}:window;window.self=window;
  if(foreignSolana)window.solana=foreignSolana;
  if(native)window.XerisWalletNative={postMessage(text){messages.push(JSON.parse(text));}};
  for(const name of ['flutter_inappwebview','XerisWallet','XerisWalletAndroid','webkit'])Object.defineProperty(window,name,{get(){throw new Error('Insecure fallback was inspected.');}});
  vm.runInNewContext(source,{window,Uint8Array,TextEncoder,btoa,atob,Event,console:{log(){},error(){},warn(){}},
    setTimeout(fn){const id=++next;timers.set(id,fn);return id;},clearTimeout(id){timers.delete(id);}});
  return{window,messages,timers,events,reply(result,error=null){const id=messages.at(-1).id;window.__xerisNativeResponse({id,result,error});}};
}
const address='US517G5965aydkZ46HS38QLi7UQiSojurfbQfKCELFx';
async function connected(f){const pending=f.window.xeris.connect();f.reply({publicKey:address,network:'xeris-mainnet'});await pending;}
test('document-scoped native transport preserves public provider API and clears completed timers',async()=>{
  const f=fixture();assert.equal(f.messages.length,0);await connected(f);assert.equal(f.messages[0].method,'connect');assert.match(f.messages[0].document_id,/^[0-9a-f]{32}$/);assert.equal(f.window.xeris.publicKey.toString(),address);assert.equal(f.timers.size,0);
  const rpc=f.window.xeris.getRpcUrl();f.reply({rpcUrl:'https://mainnetrpc.xerisweb.com'});assert.equal(await rpc,'https://mainnetrpc.xerisweb.com');assert.equal(f.timers.size,0);
});
test('embedded frames expose no wallet; HTTP and unsupported secure transport fail without a fallback',async()=>{
  assert.equal(fixture({frame:true}).window.xeris,undefined);
  for(const options of [{protocol:'http:'},{native:false}]){const f=fixture(options);await assert.rejects(f.window.xeris.connect(),/Secure wallet communication/);assert.equal(f.messages.length,0);assert.equal(f.timers.size,0);}
});
test('message signing encodes UTF-8 text exactly and decodes signature bytes without submitting',async()=>{
  const f=fixture();await connected(f);const pending=f.window.xeris.signMessage('Mainnet ownership · 你好');
  assert.equal(f.messages.at(-1).method,'signMessage');assert.equal(new TextDecoder().decode(Uint8Array.from(atob(f.messages.at(-1).params.message),c=>c.charCodeAt(0))),'Mainnet ownership · 你好');
  const signature=new Uint8Array(64).fill(11);f.reply({signature:btoa(String.fromCharCode(...signature))});assert.deepEqual([...(await pending).signature],[...signature]);assert.equal(f.messages.some(m=>m.method==='signAndSendTransaction'),false);
});
test('page closure and active-account changes reject old pending requests immediately',async()=>{
  for(const action of [f=>f.events.get('pagehide')(),f=>f.window.__xerisAccountChanged(null)]){const f=fixture();await connected(f);const pending=f.window.xeris.signTransaction('AQ==');const rejected=assert.rejects(pending,/closed|changed/);action(f);await rejected;assert.equal(f.timers.size,0);assert.equal(f.window.xeris.isConnected,false);assert.equal(f.window.xeris.publicKey,null);}
});
test('a separate Solana provider is never relabeled as an Xeris wallet',()=>{const foreign={isPhantom:true},f=fixture({foreignSolana:foreign});assert.equal(f.window.solana,foreign);assert.deepEqual(foreign,{isPhantom:true});assert.notEqual(f.window.xeris,foreign);});
test('pending resource bounds reject a seventeenth request and timeout releases every entry',async()=>{
  const f=fixture(),pending=[];for(let i=0;i<16;i++)pending.push(assert.rejects(f.window.xeris.getRpcUrl(),/timed out/));
  await assert.rejects(f.window.xeris.getRpcUrl(),/Too many/);assert.equal(f.messages.length,16);
  for(const fn of [...f.timers.values()])fn();await Promise.all(pending);
});
