/* MSG91 owns OTP generation, CAPTCHA and resend limits. No private Auth Key here. */
(() => {
  let loading;
  let active = false;
  const load = () => loading ??= new Promise((resolve, reject) => {
    if (typeof window.initSendOTP === 'function') return resolve();
    const script = document.createElement('script');
    const timer = setTimeout(() => {
      loading = undefined;
      script.remove();
      reject(new Error('SMS verification could not load.'));
    }, 15000);
    script.src = 'https://verify.msg91.com/otp-provider.js';
    script.onload = () => { clearTimeout(timer); resolve(); };
    script.onerror = () => { clearTimeout(timer); loading = undefined; script.remove(); reject(new Error('SMS verification could not load.')); };
    document.head.appendChild(script);
  });
  window.nayaMsg91Login = async (configJson, mobile) => {
    if (active) throw new Error('A verification is already in progress.');
    active = true;
    try {
      await load();
      const config = JSON.parse(configJson);
      return await new Promise((resolve, reject) => {
        let complete = false;
        const timer = setTimeout(() => finish(false), 180000);
        function finish(ok, value) {
          if (complete) return;
          complete = true;
          clearTimeout(timer);
          if (ok) resolve(value); else reject(new Error('Verification was not completed. Please try again.'));
        }
        window.initSendOTP({
          widgetId: config.widgetId,
          tokenAuth: config.widgetToken,
          identifier: '91' + mobile,
          exposeMethods: false,
          success: data => {
            const token = typeof data === 'string' ? data : data?.message;
            if (typeof token !== 'string' || token.split('.').length !== 3) return finish(false);
            finish(true, token);
          },
          failure: () => finish(false)
        });
      });
    } finally { active = false; }
  };
})();

// Custom UI bridge: Flutter renders the number and code fields on one page.
(() => {
  let configKey, ready, mobile, reqId, lastSent = 0, retries = 0, busy = false;
  const call = fn => new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('SMS_TIMEOUT')), 30000);
    fn(value => { clearTimeout(timer); resolve(value); }, () => {
      clearTimeout(timer); reject(new Error('SMS_PROVIDER_REJECTED'));
    });
  });
  window.nayaMsg91Prepare = async json => {
    if (configKey === json && ready) return ready;
    configKey = json;
    ready = (async () => {
      if (typeof window.initSendOTP !== 'function') await new Promise((resolve, reject) => {
        const script = document.createElement('script');
        script.src = 'https://verify.msg91.com/otp-provider.js';
        const timer = setTimeout(() => reject(new Error('SMS_LOAD_TIMEOUT')), 15000);
        script.onload = () => { clearTimeout(timer); resolve(); };
        script.onerror = () => { clearTimeout(timer); reject(new Error('SMS_LOAD_FAILED')); };
        document.head.appendChild(script);
      });
      const c = JSON.parse(json);
      const previousSend = window.sendOtp;
      window.initSendOTP({widgetId:c.widgetId, tokenAuth:c.widgetToken,
        exposeMethods:true, captchaRenderId:'naya-otp-captcha',
        success:()=>{}, failure:()=>{}});
      const started = Date.now();
      while (typeof window.sendOtp !== 'function' || window.sendOtp === previousSend || typeof window.verifyOtp !== 'function') {
        if (Date.now()-started > 15000) throw new Error('SMS_INIT_TIMEOUT');
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      mobile = reqId = undefined; retries = 0;
    })();
    try { await ready; } catch(e) { ready = undefined; configKey = undefined; throw e; }
  };
  window.nayaMsg91Reset = () => { configKey = ready = mobile = reqId = undefined; };
  window.nayaMsg91Send = async number => {
    if (busy) throw new Error('SMS_BUSY');
    if (!/^[6-9]\d{9}$/.test(number)) throw new Error('SMS_NUMBER');
    await ready;
    const retry = number === mobile && reqId;
    if (retry && (Date.now()-lastSent < 30000 || retries >= 2)) throw new Error('SMS_RESEND_LIMIT');
    busy = true;
    try {
      const result = await call((ok, fail) => retry
        ? window.retryOtp(null,ok,fail,reqId)
        : window.sendOtp('91'+number,ok,fail));
      if (result?.type !== 'success') throw new Error('SMS_SEND_FAILED');
      if (!retry) {
        const id = result.reqId ?? result.message;
        if (typeof id !== 'string' || !id) throw new Error('SMS_REQUEST_MISSING');
        reqId = id; mobile = number; retries = 0;
      } else retries++;
      lastSent = Date.now();
      return 'sent';
    } finally { busy = false; }
  };
  window.nayaMsg91Verify = async (number, code) => {
    if (busy) throw new Error('SMS_BUSY');
    if (mobile !== number || !reqId || !/^\d{6}$/.test(code)) throw new Error('SMS_CHALLENGE');
    busy = true;
    try {
      const result = await call((ok,fail) => window.verifyOtp(code,ok,fail,reqId));
      const proof = result?.['access-token'] ?? result?.message;
      if (result?.type !== 'success' || typeof proof !== 'string' || proof.split('.').length !== 3)
        throw new Error('SMS_PROOF_MISSING');
      reqId = undefined;
      return proof;
    } finally { busy = false; }
  };
})();
