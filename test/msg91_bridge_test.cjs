// Run with node --test test/msg91_bridge_test.cjs. No provider traffic or credentials.
const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const source = fs.readFileSync('web/msg91-login.js','utf8');
function bridge(callback) {
  const window = {initSendOTP: callback};
  vm.runInNewContext(source,{window,setTimeout,clearTimeout});
  return window.nayaMsg91Login;
}
test('passes only public configuration and country-prefixed mobile to widget',async()=>{
  let options;
  const login=bridge(config=>{options=config;config.success({message:'header.payload.signature'});});
  assert.equal(await login(JSON.stringify({widgetId:'widget',widgetToken:'public'}),'9121304215'),'header.payload.signature');
  assert.equal(options.identifier,'919121304215');
  assert.equal(options.tokenAuth,'public');
  assert.equal(options.authkey,undefined);
});
test('rejects error and malformed proof, allowing a subsequent attempt',async()=>{
  const login=bridge(config=>config.success({message:'not-a-proof'}));
  await assert.rejects(login('{}','9121304215'));
  await assert.rejects(login('{}','9121304215'));
});
test('prevents overlapping widget sessions',async()=>{
  let options;
  const login=bridge(config=>{options=config;});
  const first=login('{}','9121304215');
  await assert.rejects(login('{}','9121304215'));
  options.failure();
  await assert.rejects(first);
});
