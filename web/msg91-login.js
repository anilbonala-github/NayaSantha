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
