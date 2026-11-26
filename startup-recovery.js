(() => {
  window.shatranjShowStartupFailure = error => {
    window.shatranjStartupFailed = true;
    const raw = error instanceof Error ? error.message : String(error);
    const graphics = /webgl|graphics context|context creation/i.test(raw);
    const notice = document.getElementById('status-notice');
    const intro = document.querySelector('.loading-intro p');
    if (intro) intro.textContent = 'The game has not started yet.';
    notice.replaceChildren();
    notice.className = 'startup-recovery';
    notice.setAttribute('role','alert');
    const add = (tag,text,parent=notice) => {
      const node=document.createElement(tag);node.textContent=text;parent.appendChild(node);return node;
    };
    add('h2',graphics ? '3D graphics could not start' : 'The game could not load');
    add('p',graphics ? 'This browser could not provide the graphics support needed for the battlefield. This can be temporary; it does not necessarily mean your phone is unsupported.' : 'Check your connection, then retry. If an update is available, you can apply it without reinstalling.');
    if (graphics) {
      const steps=add('ol','');
      add('li','Close floating videos and other 3D games, fully close Shatranj, then reopen it.',steps);
      add('li','If it still fails, open the link directly in Chrome. Updating Chrome or restarting your phone may help.',steps);
      add('p','Retry cannot bypass missing WebGL2 support. You do not need to uninstall Shatranj.');
    }
    const actions=add('div','');actions.className='startup-actions';
    const retry=add('button','Retry',actions);retry.type='button';retry.addEventListener('click',()=>location.reload());
    const url='https://invincy.github.io/shatranj/';
    const open=add('a',/Android/i.test(navigator.userAgent)?'Open in Chrome':'Open game in browser',actions);
    open.href=/Android/i.test(navigator.userAgent)?'intent://invincy.github.io/shatranj/#Intent;scheme=https;package=com.android.chrome;S.browser_fallback_url='+encodeURIComponent(url)+';end':url;
    const link=add('a','Game link: invincy.github.io/shatranj/');link.href=url;link.target='_blank';link.rel='noopener';
    const details=add('details','');add('summary','Technical details',details);add('p',raw,details);
    window.dispatchEvent(new Event('shatranj-startup-failed'));
  };
})();
