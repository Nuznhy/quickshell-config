#!/usr/bin/env python3
import json, os, pathlib, subprocess, time
# Run every invocation on a private bus so tests never clear desktop history.
import shutil, sys, tempfile
ROOT = pathlib.Path(__file__).resolve().parent.parent
if '--isolated' not in sys.argv:
    subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', str(ROOT / 'tests/notifications'), '-v'], check=True)
    with tempfile.TemporaryDirectory(prefix='qs-notifications-test-') as directory:
        child_env = os.environ.copy()
        child_env['QS_NOTIFICATION_TEST_DIR'] = directory
        sys.exit(subprocess.call(['dbus-run-session', '--', sys.executable, __file__, '--isolated'], env=child_env))
BASE = os.environ['QS_NOTIFICATION_TEST_DIR']
for name in ['components', 'config', 'services']:
    shutil.copytree(ROOT / name, pathlib.Path(BASE) / name)
shutil.copyfile(ROOT / 'tests/notifications/shell.qml', pathlib.Path(BASE) / 'shell.qml')
(pathlib.Path(BASE) / 'scripts').mkdir()
for name in ['focus-notification.py', 'focus-window.sh']:
    shutil.copyfile(ROOT / 'scripts' / name, pathlib.Path(BASE) / 'scripts' / name)
mockbin = pathlib.Path(BASE) / 'mockbin'
mockbin.mkdir()
hyprctl = mockbin / 'hyprctl'
hyprctl.write_text("""#!/usr/bin/env python3
import json, os, pathlib, sys
with (pathlib.Path(os.environ['QS_NOTIFICATION_TEST_DIR']) / 'focus-calls.jsonl').open('a') as output:
    output.write(json.dumps(sys.argv[1:]) + '\\n')
window = {'address': '0xabc', 'class': 'Test actions', 'mapped': True, 'focusHistoryID': 0, 'at': [0, 0], 'size': [800, 600]}
print(json.dumps([window] if sys.argv[1] == 'clients' else window) if sys.argv[1] in ['clients', 'activewindow'] else 'ok')
""")
hyprctl.chmod(0o700)

for name, filename in [('config/Theme.qml', 'theme.json'), ('services/Notifications.qml', 'notifications.json')]:
    path = pathlib.Path(BASE) / name
    path.write_text(path.read_text().replace('Quickshell.statePath("' + filename + '")', json.dumps(BASE + '/' + filename)))
env=os.environ.copy()
env['PATH'] = str(mockbin) + os.pathsep + env.get('PATH', '')
env['QT_QPA_PLATFORM']='offscreen'
env.pop('WAYLAND_DISPLAY', None)
for variable, name in [('XDG_RUNTIME_DIR', 'runtime'), ('XDG_STATE_HOME', 'state'), ('XDG_CACHE_HOME', 'cache')]:
    path = pathlib.Path(BASE) / name
    path.mkdir(mode=0o700)
    env[variable] = str(path)
def run(*args):
    return subprocess.check_output(args, env=env, text=True, stderr=subprocess.STDOUT).strip()
def ipc(target, method, *args):
    return run('quickshell','ipc','-p',BASE,'call',target,method,*map(str,args))
def state():
    result = ipc('test', 'snapshot')
    try: return json.loads(result)
    except ValueError: raise AssertionError('Invalid snapshot: ' + repr(result))
def notify(title, body='Test notification', timeout=-1, replace=0, urgency='normal', transient=False):
    args=['notify-send','-p','-a','Quickshell Test','-i','dialog-information','-t',str(timeout),'-u',urgency]
    if replace: args += ['-r',str(replace)]
    if transient: args += ['-h','boolean:transient:true']
    return int(run(*args,title,body))
def check(ok,label):
    if not ok: raise AssertionError(label)
    print('PASS:',label,flush=True)
def wait_ready():
    for _ in range(60):
        try:
            if state()['ready']: return
        except Exception: pass
        time.sleep(.1)
    raise RuntimeError('server did not start')
log=open(BASE+'/runtime.log','w')
p=subprocess.Popen(['quickshell','-p',BASE,'--no-color'],env=env,stdout=log,stderr=log)
try:
    wait_ready()
    for during_close in [False, True]:
        ipc('test', 'openPopup')
        time.sleep(.25)
        check(state()['popupVisible'], 'popup opens with a mapped native window')
        if during_close:
            ipc('test', 'switchWorkspace')
        ipc('test', 'dismissPopup')
        check(not state()['popupOpen'] and not state()['popupVisible'], 'native dismissal clears popup state')
        # Reopen before the 130 ms exit animation could finish on its own.
        ipc('test', 'openPopup')
        time.sleep(.25)
        check(state()['popupOpen'] and state()['popupVisible'], 'popup reopens after interrupted dismissal')
        for _ in range(5):
            ipc('test', 'switchWorkspace')
            ipc('test', 'openPopup')
        time.sleep(.25)
        check(state()['popupOpen'] and state()['popupVisible'], 'rapid workspace close/reopen keeps popup usable')
        ipc('test', 'switchWorkspace')
        time.sleep(.2)
    ipc('notifications','clear'); ipc('notifications','dnd','false')
    n=notify('Build finished','All checks passed. Your notification center is ready.')
    s=state(); check(len(s['entries'])==1 and s['popups']==1,'receive and show notification')
    key=s['entries'][0]['key']
    notify('Build updated','Replacement stays a single entry.',replace=n)
    time.sleep(.1)
    s=state(); check(len(s['entries'])==1 and s['entries'][0]['summary']=='Build updated' and s['entries'][0]['key']==key,'replace notification in place')
    ipc('notifications','dnd','true')
    notify('Quiet mode','Collected without interrupting you.')
    s=state(); check(s['dnd'] and len(s['entries'])==2 and s['popups']==0,'DND suppresses toasts but retains history')
    ipc('notifications','dnd','false')
    check(state()['popups']==0,'disabling DND does not replay old toasts')
    notify('Short notification',timeout=250)
    time.sleep(.45)
    s=state(); check(s['popups']==0 and len(s['entries'])==3 and s['watchers']==2,'expiry retains snapshot and releases live object')
    notify('Transient',timeout=200,transient=True)
    time.sleep(.4)
    check(len(state()['entries'])==3,'transient notification is not retained')
    n=notify('App closed this')
    run('gdbus','call','--session','--dest','org.freedesktop.Notifications','--object-path','/org/freedesktop/Notifications','--method','org.freedesktop.Notifications.CloseNotification',str(n))
    check(state()['popups']==0 and len(state()['entries'])==4,'client close removes toast and keeps history')
    notify('Critical notification','Needs your attention.',urgency='critical',timeout=200)
    time.sleep(.4)
    check(state()['popups']==1,'critical notification stays until dismissed')
    ipc('test','open')
    check(state()['popups']==0 and all(e['read'] for e in state()['entries']),'opening center marks read and hides toasts')
    notify('While reading history')
    check(state()['popups']==0 and state()['entries'][0]['read'],'open center receives quietly')
    ipc('test','close')
    ipc('notifications','clear')
    for i in range(103): notify('History item '+str(i),timeout=0)
    s=state(); check(len(s['entries'])==100 and s['watchers']==100 and s['popups']==3,'history/live object cap and three-toast limit')
    changes = s['historyChanges']
    ipc('test', 'open')
    s = state()
    check(s['historyChanges'] - changes <= 2 and s['popups'] == 0 and all(e['read'] for e in s['entries']),
          'opening a full history batches read and toast updates')
    changes = s['historyChanges']
    for _ in range(5):
        ipc('test', 'close')
        ipc('test', 'open')
    check(state()['historyChanges'] == changes, 'reopening read history does not rebuild notification cards')
    ipc('test', 'close')
    notify('Dismiss transient on open', timeout=0, transient=True)
    ipc('test', 'open')
    check(not any(e['transient'] for e in state()['entries']), 'opening history expires transient toasts')
    ipc('test', 'close')
    ipc('notifications','clear')
    check(not state()['entries'] and state()['watchers']==0,'clear history releases tracked objects')
    # Exercise a real freedesktop action rather than a mocked QML method.
    monitor=subprocess.Popen(['gdbus','monitor','--session','--dest','org.freedesktop.Notifications','--object-path','/org/freedesktop/Notifications'],env=env,stdout=subprocess.PIPE,text=True)
    time.sleep(.15)
    run('gdbus','call','--session','--dest','org.freedesktop.Notifications','--object-path','/org/freedesktop/Notifications','--method','org.freedesktop.Notifications.Notify','Test actions','0','dialog-information','Ready to open','Action test',"['default', 'Open']","{}",'0')
    s=state(); check(len(s['entries'][0]['actions'])==1,'app actions displayed')
    ipc('test','open')
    ipc('test','invoke',s['entries'][0]['key'],'default')
    time.sleep(.1); monitor.terminate(); out=monitor.communicate(timeout=2)[0]
    check('ActionInvoked' in out and not state()['entries'][0]['actions'],'action callback delivered and stale action removed')
    time.sleep(.5)
    calls = [json.loads(line) for line in pathlib.Path(BASE+'/focus-calls.jsonl').read_text().splitlines()]
    check(any(call[0] == 'dispatch' and 'address:0xabc' in call[1] for call in calls), 'Open focuses the sender through the window-focus helper')
    check(not state()['centerActive'], 'Open closes history before focusing the app')
    ipc('notifications','clear')
    notify('Build finished','All checks passed. Your notification center is ready.')
    time.sleep(.25)
    reload_path = pathlib.Path(BASE+'/shell.qml')
    reload_path.write_text(reload_path.read_text() + '\n// Verify hot reload\n')
    time.sleep(.8)
    check(len(state()['entries'])==1 and state()['watchers']==1 and state()['popups']==0, 'hot reload keeps one history entry and reattaches live notification')
    notify('Auto-hide check')
    time.sleep(6.2)
    check(state()['popups']==0 and state()['watchers']==2, 'default timeout hides toast while keeping actions available')
    ipc('notifications','dnd','true')
    notify('Quiet mode enabled','Notifications still arrive here while Do Not Disturb is on.')
    ipc('test','screenshot'); time.sleep(.4)
    before=state()['entries']; ipc('test','quit'); p.wait(timeout=3)
    p=subprocess.Popen(['quickshell','-p',BASE,'--no-color'],env=env,stdout=log,stderr=log)
    wait_ready(); s=state()
    check(s['dnd'] and len(s['entries'])==len(before) and s['popups']==0 and s['watchers']==0,'history and DND survive restart without stale actions or replay')
    ipc('test','quit'); p.wait(timeout=3)
finally:
    if p.poll() is None: p.terminate(); p.wait(timeout=3)
    log.close()
    output = pathlib.Path(BASE+'/runtime.log').read_text()
    if sys.exc_info()[0]: print(output, file=sys.stderr)
    if 'ERROR' in output or 'TypeError' in output or 'ReferenceError' in output:
        print(output, file=sys.stderr)
        raise AssertionError('runtime log contains errors')
