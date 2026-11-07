const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm'), assert = require('node:assert/strict');

const aaRoot = path.resolve(__dirname, '../../../usb/tweaks/android-auto');
const repo = path.resolve(aaRoot, '../../..');

const queue = [];
const hostEvents = {};
const viewEvents = {};
const timers = new Map();
let timer = 0, writes = 0, reboots = 0, control = null, dialogConfig = null, created = 0, destroyed = 0, attached = true, sb = 'Applications';

function element(tagName) {
    return {
        tagName: tagName || 'div',
        children: [],
        style: { cssText: '' },
        className: '',
        attributes: {},
        textContent: '',
        appendChild(e) { e.parentNode = this; this.children.push(e); },
        removeChild(e) { this.children.splice(this.children.indexOf(e), 1); e.parentNode = null; },
        get firstChild() { return this.children[0] || null; },
        set innerHTML(v) { this.children = []; },
        setAttribute(k, v) { this.attributes[k] = v; }
    };
}

function findElement(node, className) {
    if (node.className === className) { return node; }
    for (let i = 0; i < node.children.length; i += 1) {
        const found = findElement(node.children[i], className);
        if (found) { return found; }
    }
    return null;
}

const status = element(), rootNode = element(), frame = element();
rootNode.style.cssText = 'old-style';
rootNode.appendChild(frame);

const head = element('head'), body = element('body');
const document = {
    body: body,
    getElementById: () => status,
    getElementsByTagName: name => name === 'head' ? [head] : name === 'iframe' ? [frame] : [],
    createElement: tagName => element(tagName)
};
let lastSbn = null;
let backFocused = false;
const common = {
    setSbName: v => { sb = v; },
    setSbNameId: (app, id) => { sb = id; },
    startTimedSbn: (uiaId, sbnId, type, props) => {
        lastSbn = { uiaId: uiaId, sbnId: sbnId, type: type, props: props };
    },
    leftBtn: {
        btnInstance: {
            get hasFocus() { return backFocused; }
        },
        handleControllerEvent(event) {
            if (event === 'acceptFocusFromRight') {
                backFocused = true;
                return 'consumed';
            }
            if (event === 'lostFocus') {
                backFocused = false;
                return 'consumed';
            }
            if (event === 'rightStart' && backFocused) {
                return 'giveFocusRight';
            }
            return 'ignored';
        }
    }
};

const originalSend = () => {};
const fw = {
    common: common,
    _frameworkState: 'idle',
    _templatesLoaded: {},
    _controlsLoaded: {},
    _processedFilePaths: {},
    registerCtrlLoaded(name) {
        this._controlsLoaded[name] = { isLoaded: true, nameCounter: 0 };
    },
    registerTmpltLoaded(name) {
        this._templatesLoaded[name] = { isLoaded: true, nameCounter: 0 };
    },
    getCurrentApp: () => 'system',
    getCurrCtxtId: () => 'Applications',
    getAppInstance: () => ({
        _currentContextTemplate: {
            divElt: { style: { visibility: 'hidden' } },
            list2Ctrl: { setLineNumbers() { this.restored = true; } }
        }
    }),
    sendEventToMmui: originalSend,
    instantiateControl(app, parent, type, props) {
        assert.equal(type, 'List2Ctrl');
        assert.equal(props.titleConfiguration, 'noTitle');
        assert.equal(props.numberedList, true);
        assert(parent.className.indexOf('TemplateWithStatusLeft List2Tmplt') === 0);
        created++;
        control = {
            props: props,
            rendered: true,
            focus: props.focussedItem || 0,
            hasFocus: true,
            dataList: props.dataList,
            handleControllerEvent(event) {
                if (event === 'acceptFocusInit') {
                    this.hasFocus = true;
                }
                if (event === 'leftStart') { return 'giveFocusLeft'; }
                if (event === 'acceptFocusFromLeft' || event === 'acceptFocusFromRight') {
                    this.hasFocus = true;
                    return 'consumed';
                }
                if (event === 'lostFocus') {
                    this.hasFocus = false;
                    return 'consumed';
                }
                if (event === 'cw' || event === 'down') {
                    this.focus = (this.focus + 1) % this.dataList.items.length;
                }
                if (event === 'ccw' || event === 'up') {
                    this.focus = (this.focus + this.dataList.items.length - 1) % this.dataList.items.length;
                }
                if (event === 'select') {
                    props.selectCallback(this, this.dataList.items[this.focus].appData);
                }
            },
            getContextCapture() {
                return { hasFocus: this.hasFocus, focussedItem: this.focus, topItem: 0 };
            },
            restoreContext(c) {
                this.focus = c.focussedItem;
            },
            setDataList(d) {
                this.dataList = d;
                this.rendered = false;
            },
            setDataListAndUpdateItems(d) {
                this.dataList = d;
                this.rendered = true;
            }
        };
        return control;
    },
    instantiateTemplate(app, parent, type, props) {
        assert.equal(type, 'Dialog3Tmplt');
        assert.equal(this._templatesLoaded.Dialog3Tmplt.isLoaded, true, 'OEM template assets are registered before instantiation');
        assert.equal(this._frameworkState, 'idle', 'Instantiating a preloaded dialog does not change framework state');
        assert.equal(parent.parentNode, body, 'OEM dialog root is a body-level overlay');
        dialogConfig = props.Dialog3Ctrl;
        const buttons = [dialogConfig.buttonConfig.button1, dialogConfig.buttonConfig.button2];
        let dialogFocus = dialogConfig.initialFocus || 0;
        const dialogElement = element();
        dialogElement.className = 'TemplateFull Dialog3Tmplt';
        parent.appendChild(dialogElement);
        return {
            divElt: dialogElement,
            dialog3Ctrl: {},
            cleanUp() {},
            handleControllerEvent(event) {
                if (event === 'right' || event === 'down' || event === 'cw') {
                    dialogFocus = 1;
                }
                if (event === 'left' || event === 'up' || event === 'ccw') {
                    dialogFocus = 0;
                }
                if (event === 'select') {
                    dialogConfig.defaultSelectCallback(this, buttons[dialogFocus].appData);
                }
            }
        };
    },
    destroyControl(c) {
        destroyed++;
        if (control === c) { control = null; }
    }
};

head.appendChild = function (node) {
    node.parentNode = head;
    head.children.push(node);
    if (node.tagName === 'link') {
        node.onload();
    } else if (node.src.indexOf('ButtonCtrl.js') >= 0) {
        fw.registerCtrlLoaded('ButtonCtrl');
        node.onload();
    } else if (node.src.indexOf('Dialog3Ctrl.js') >= 0) {
        fw.registerCtrlLoaded('Dialog3Ctrl');
        node.onload();
    } else if (node.src.indexOf('Dialog3Tmplt.js') >= 0) {
        fw.registerTmpltLoaded('Dialog3Tmplt');
        node.onload();
    } else {
        assert.fail('Unexpected Mazda dialog asset: ' + node.src);
    }
};

let intervalsStarted = 0, intervalsCleared = 0;
const host = {
    location: { hostname: 'localhost', origin: undefined },
    framework: fw,
    addEventListener: (n, f) => { hostEvents[n] = f; },
    removeEventListener: n => { delete hostEvents[n]; },
    setTimeout: (f, ms) => {
        timers.set(++timer, { f: f, ms: ms });
        return timer;
    },
    clearTimeout: n => timers.delete(n),
    setInterval: f => { intervalsStarted++; host.refresh = f; return intervalsStarted; },
    clearInterval: () => { intervalsCleared++; delete host.refresh; }
};

const parent = {
    postMessage: data => queue.push(() => {
        if (hostEvents.message) {
            hostEvents.message({ source: view, data: data });
        }
    })
};

const view = {
    parent: parent,
    location: { hash: '#mzdgui=fixture-token' },
    addEventListener: (n, f) => (viewEvents[n] || (viewEvents[n] = [])).push(f),
    removeEventListener: (n, f) => {
        if (viewEvents[n]) {
            viewEvents[n] = viewEvents[n].filter(x => x !== f);
            if (!viewEvents[n].length) delete viewEvents[n];
        }
    },
    setTimeout: host.setTimeout,
    clearTimeout: host.clearTimeout,
    postMessage: (data, target) => {
        assert.equal(target, '*', 'Wildcard target required for file-origin postMessage');
        queue.push(() => {
            for (const f of (viewEvents.message || []).slice()) {
                f({ source: parent, data: data });
            }
        });
    }
};

frame.contentWindow = view;
const frames = [frame];

let savedSettings = {
    touch: true,
    hud: true,
    hud_transport: 'svcnavi',
    force_street_name: false,
    hud_fold_latin: true,
    use_protocol_v1_6: true,
    roundabout_prepend_exit_number: false,
    hud_maneuver_max_distance_m: 0,
    compass_always_on: false,
    bt_pairing_bypass_all_devices: false,
    bt_pairing_show_device_notification: false,
    mute_pauses_phone: true,
    unmute_starts_playback: false,
    block_headunit_media_play: true,
    aa_audio_low_latency: false
};

const resident = {
    onServiceReady: fn => { resident.reconnected = fn; },
    view: () => ({ source: view, frame: frame, token: 'fixture-token' }),
    onMessage: fn => { hostEvents.message = fn; },
    onViewClose: fn => { resident.closed = fn; },
    onDispose: fn => { hostEvents.unload = fn; },
    service: {
        request(op, args, cb) {
            queue.push(() => {
                if (op === 'get') {
                    cb(null, { success: true, settings: Object.assign({}, savedSettings) });
                } else if (op === 'set') {
                    writes++;
                    savedSettings[args.key] = args.value;
                    cb(null, { success: true, settings: Object.assign({}, savedSettings) });
                } else if (op === 'reboot') {
                    reboots++;
                    cb(null, { success: true });
                } else {
                    throw Error('Unexpected operation: ' + op);
                }
            });
        }
    }
};

host.MzdGuiResidents = {
    register(id, fn) {
        assert.equal(id, 'android-auto');
        fn(resident);
    }
};

const hostContext = {
    window: host,
    document: document
};
document.documentElement = { contains: () => attached };

// Run resident script
vm.runInNewContext(fs.readFileSync(path.join(aaRoot, 'assets/resident.js'), 'utf8'), hostContext);
assert.equal(host.AaNativeMenu, undefined, 'No global namespace pollution');
assert.equal(intervalsStarted, 0, 'Polling interval not started at resident registration');

// Run SDK
vm.runInNewContext(fs.readFileSync(path.join(repo, 'usb/lib/gui-runtime/sdk.js'), 'utf8'), { window: view });

// Run view script
vm.runInNewContext(fs.readFileSync(path.join(aaRoot, 'assets/view.js'), 'utf8'), { window: view, document: document });

// Deliver i18n dictionary to SDK
let dictionary;
vm.runInNewContext(fs.readFileSync(path.join(aaRoot, 'assets/i18n.js'), 'utf8'), {
    window: {
        MzdGuiI18n: {
            register(id, value) { dictionary = value; }
        }
    }
});
const texts = dictionary.languages.en_US;
for (const [locale, language] of Object.entries(dictionary.languages)) {
    for (const key of ['reboot', 'rebootNotice']) {
        assert.equal(typeof language[key], 'string', 'Every language has the ' + key + ' translation');
    }
    assert.equal(typeof language.rebootQuestion, 'string', 'Every language has a reboot confirmation question');
    if (locale.indexOf('en_') !== 0) {
        assert.notEqual(language.rebootQuestion, 'Do you want to reboot MZD to apply Android Auto settings?', locale + ' has a translated reboot question');
    }
    assert.equal(typeof language.rebootError, 'string', 'Every language has a reboot instruction notification');
    assert.equal(language.rebootError.length <= 48, true, 'Reboot instruction notification fits a short message');
    assert.equal(Object.prototype.hasOwnProperty.call(language, 'rebootInstructions'), false, 'Obsolete reboot instructions are removed');
}
assert.equal(texts.rebootQuestion, 'Do you want to reboot MZD to apply Android Auto settings?');
assert.equal(texts.rebootError, 'Hold NAV + MUTE to reboot');
for (const fn of viewEvents.message.slice()) {
    fn({
        source: parent,
        data: {
            type: 'mzd-gui-language',
            token: 'fixture-token',
            value: { language: 'en_US', direction: 'ltr', texts: texts }
        }
    });
}

function flush() {
    let n = 0;
    while (queue.length) {
        assert(++n < 200, 'message loop safety check');
        queue.shift()();
    }
    const ready = [...timers.entries()].filter(([id, t]) => t.ms === 0);
    for (const [id, t] of ready) {
        timers.delete(id);
        t.f();
    }
    if (queue.length) flush();
}

function click(i) {
    control.focus = i;
    control.props.selectCallback(control, control.dataList.items[i].appData);
    flush();
}

function input(action, phase = 'step') {
    for (const f of viewEvents.message.slice()) {
        f({ source: parent, data: { type: 'mzd-gui-input', token: 'fixture-token', action: action, phase: phase } });
    }
    flush();
}

// 1. Initial load
flush();
assert.equal(intervalsStarted, 1, 'Polling interval started on view open');
assert.equal(sb, 'Android Auto Settings');
assert.equal(control.dataList.items.length, 16);
assert.equal(control.props.smallItemText, true, 'AA settings use the Safety-tab compact text size');

// Check first row (touch): boolean toggle -> styleOnOff, value 1 (on)
assert.equal(control.dataList.items[0].text1, 'Touchscreen while driving');
assert.equal(control.dataList.items[0].itemStyle, 'styleOnOff');
assert.equal(control.dataList.items[0].value, 1);
assert.equal(control.dataList.items[0].checked, true);
assert.equal(control.dataList.items[0].hasCaret, false);

// Check row 2 (hud_transport): styleOnOff, value 1 (svcnavi is on)
assert.equal(control.dataList.items[2].text1, 'Show speed limit with Nav SD');
assert.equal(control.dataList.items[2].itemStyle, 'styleOnOff');
assert.equal(control.dataList.items[2].value, 1);
assert.equal(control.dataList.items[2].checked, true);

// Check row 7 (hud_maneuver_max_distance_m): style06 with label1="Default" and hasCaret=true
assert.equal(control.dataList.items[7].text1, 'Show HUD turns within');
assert.equal(control.dataList.items[7].itemStyle, 'style06');
assert.equal(control.dataList.items[7].label1, 'Default');
assert.equal(control.dataList.items[7].hasCaret, true);

// 1b. Reboot action uses the OEM reset icon and opens the two-button confirmation dialog
assert.equal(control.dataList.items[15].text1, 'Reboot to apply changes');
assert.equal(control.dataList.items[15].image1, 'common/images/icons/IcnUmpReset_En.png');
control.hasFocus = false;
click(15);
assert.equal(dialogConfig.text1, 'Do you want to reboot MZD to apply Android Auto settings?');
assert.equal(dialogConfig.initialFocus, 0, 'No is the default selection');
assert.equal(dialogConfig.buttonConfig.button1.labelId, 'common.No', 'OEM dialog uses the localized No button first');
assert.equal(dialogConfig.buttonConfig.button1.appData, 'no');
assert.equal(dialogConfig.buttonConfig.button2.labelId, 'common.Yes', 'OEM dialog uses the localized Yes button second');
assert.equal(dialogConfig.buttonConfig.button2.appData, 'yes');
assert.notEqual(findElement(body, 'TemplateFull Dialog3Tmplt'), null, 'The OEM dialog covers the full interface');
assert.equal(fw._frameworkState, 'idle', 'Opening the dialog does not enter the framework template-loading state');
input('select');
flush();
assert.equal(reboots, 0, 'Default No selection does not reboot');
assert.equal(findElement(body, 'TemplateFull Dialog3Tmplt'), null, 'Selecting No removes the OEM dialog');
assert.equal(control.hasFocus, true, 'Dismissing the dialog restores list focus');
const focusBeforeDialogDismissal = control.focus;
input('down');
assert.notEqual(control.focus, focusBeforeDialogDismissal, 'List navigation works after dismissing the dialog');

click(15);
assert.notEqual(findElement(body, 'TemplateFull Dialog3Tmplt'), null, 'Confirmation dialog can be opened again');
input('right');
input('select');
flush();
assert.equal(findElement(body, 'TemplateFull Dialog3Tmplt'), null, 'Selecting Yes removes the OEM dialog');
assert.equal(reboots, 1, 'Yes requests reboot through the GUI service');

// 2. Click touch row (toggle to OFF)
click(0);
assert.equal(savedSettings.touch, false);
assert.equal(control.dataList.items[0].value, 2);
assert.equal(control.dataList.items[0].checked, false);
assert.equal(writes, 1);
assert.equal(lastSbn.type, 'typeD');
assert.equal(lastSbn.props.text1, 'Settings saved', 'Successful saves notify while the settings view stays open');

// Click again (toggle to ON)
click(0);
assert.equal(savedSettings.touch, true);
assert.equal(control.dataList.items[0].value, 1);
assert.equal(control.dataList.items[0].checked, true);
assert.equal(writes, 2);

// 3. Click hud_transport row (toggle to vbs / OFF)
click(2);
assert.equal(savedSettings.hud_transport, 'vbs');
assert.equal(control.dataList.items[2].value, 2);
assert.equal(control.dataList.items[2].checked, false);
assert.equal(writes, 3);

// 3b. Rapid consecutive clicks while save is in flight (queueing & race safety)
let holdService = true;
const heldCallbacks = [];
const origServiceRequest = resident.service.request;
const holdRequest = function (op, args, cb) {
    if (holdService && op === 'set') {
        queue.push(() => {
            writes++;
            savedSettings[args.key] = args.value;
            heldCallbacks.push(err => {
                if (err) {
                    cb(err);
                } else {
                    cb(null, { success: true, settings: Object.assign({}, savedSettings) });
                }
            });
        });
    } else {
        origServiceRequest.call(this, op, args, cb);
    }
};
resident.service.request = holdRequest;

// User toggles touch to false (in flight, held)
click(0);
assert.equal(control.dataList.items[0].checked, false);
assert.equal(writes, 4);

// User immediately toggles hud to false while touch save is still in flight
click(1);
assert.equal(control.dataList.items[1].checked, false);
// Second request was queued in view.js, not yet sent to service
assert.equal(writes, 4);

// First save completes
holdService = false;
heldCallbacks.shift()();
flush(); // Processes first response, which sends the queued second request and its response
assert.equal(writes, 5);
resident.service.request = origServiceRequest;

// Verify both settings were successfully saved and UI reflects both
assert.equal(savedSettings.touch, false);
assert.equal(savedSettings.hud, false);
assert.equal(control.dataList.items[0].checked, false);
assert.equal(control.dataList.items[1].checked, false);

// Restore touch and hud to true
click(0);
assert.equal(savedSettings.touch, true);
click(1);
assert.equal(savedSettings.hud, true);
assert.equal(writes, 7);

// 4. Click distance row -> enters distance submenu
click(7);
assert.equal(sb, 'Show HUD turns within');
assert.equal(control.dataList.items.length, 10); // 10 distance options

// Verify distance options: style03, image1 'tick', only 0m (Default) is checked
assert.equal(control.dataList.items[0].text1, 'Default');
assert.equal(control.dataList.items[0].itemStyle, 'style03');
assert.equal(control.dataList.items[0].image1, 'tick');
assert.equal(control.dataList.items[0].checked, true);

assert.equal(control.dataList.items[1].text1, '500 m');
assert.equal(control.dataList.items[1].itemStyle, 'style03');
assert.equal(control.dataList.items[1].image1, 'tick');
assert.equal(control.dataList.items[1].checked, false);

assert.equal(control.dataList.items[2].text1, '1 km');
assert.equal(control.dataList.items[2].checked, false);

// 5. Select 1 km option (index 2)
click(2);
assert.equal(savedSettings.hud_maneuver_max_distance_m, 1000);
assert.equal(sb, 'Android Auto Settings', 'Accepting a distance returns to Android Auto settings');
assert.equal(control.dataList.items.length, 16);
assert.equal(control.dataList.items[7].label1, '1 km');
assert.equal(control.focus, 7, 'Returning restores focus to the distance setting');
assert.equal(writes, 8);

// Verify that the distance row displays "1 km" on the right hand side
assert.equal(control.dataList.items[7].text1, 'Show HUD turns within');
assert.equal(control.dataList.items[7].label1, '1 km');
assert.equal(control.dataList.items[7].hasCaret, true);

// 6. Back navigation from main menu closes view
input('left');
assert.equal(backFocused, true, 'Left from the list transfers focus to the Mazda Back button');
input('right');
assert.equal(backFocused, false, 'Right from the Back button returns focus to the settings list');
input('left');
assert.equal(backFocused, true, 'Back button can be focused again');
input('back');
// Runtime calls onViewClose when view requests close
resident.closed();
assert.equal(sb, 'Applications', 'Closing Android Auto settings restores the Applications header even when its template is hidden');
assert.equal(lastSbn.props.text1, 'Reboot to apply settings', 'Leaving after a successful save prompts for a reboot');
assert.equal(intervalsCleared, 1, 'Polling interval cleared on view close');
assert.equal(host.refresh, undefined, 'Polling callback removed');
assert.equal(control, null, 'List control destroyed on close');
assert.equal(fw.sendEventToMmui, originalSend, 'Original sendEventToMmui restored');

// Cleanup
view.MzdGuiModule._dispose();
flush();

// 8. Test background save completion and SBN notification on exit
lastSbn = null;
holdService = true;
resident.service.request = holdRequest;
hostEvents.message({
    source: view,
    data: {
        type: 'aa-request',
        token: 'fixture-token',
        action: 'set',
        payload: { key: 'touch', value: false }
    }
});
flush();
assert.equal(writes, 9);

// Driver leaves menu while save is in flight
hostEvents.message({
    source: view,
    data: {
        type: 'aa-native-release',
        token: 'fixture-token',
        savingMessage: 'Saving Android Auto settings...',
        savedMessage: 'Android Auto settings saved.'
    }
});
flush();
resident.closed();

assert.notEqual(lastSbn, null, 'Saving SBN emitted on exit while save in flight');
assert.equal(lastSbn.uiaId, 'androidauto');
assert.equal(lastSbn.type, 'typeD');
assert.equal(lastSbn.props.sbnStyle, 'Style02');
assert.equal(lastSbn.props.text1, 'Saving Android Auto settings...');
assert.equal(lastSbn.props.imagePath1, 'common/images/icons/IcnSbnApps.png');

// Background save finishes
lastSbn = null;
holdService = false;
heldCallbacks.shift()();
flush();

assert.notEqual(lastSbn, null, 'Saved SBN emitted when background save finished');
assert.equal(lastSbn.type, 'typeD');
assert.equal(lastSbn.props.text1, 'Reboot to apply settings');
assert.equal(savedSettings.touch, false);

// 8b. Untrusted aa-native-release is ignored
lastSbn = null;
hostEvents.message({
    source: {},
    data: {
        type: 'aa-native-release',
        token: 'untrusted-token',
        savingMessage: 'Spoofed toast',
        savedMessage: 'Spoofed toast'
    }
});
assert.equal(lastSbn, null, 'Untrusted aa-native-release ignored');

// 8c. Localized error SBN emitted when background save fails
lastSbn = null;
holdService = true;
resident.service.request = holdRequest;
hostEvents.message({
    source: view,
    data: {
        type: 'aa-request',
        token: 'fixture-token',
        action: 'set',
        payload: { key: 'force_street_name', value: true }
    }
});
flush();
hostEvents.message({
    source: view,
    data: {
        type: 'aa-native-release',
        token: 'fixture-token',
        savingMessage: 'Enregistrement...',
        savedMessage: 'Enregistré.',
        errorMessage: 'Échec de l’enregistrement'
    }
});
flush();
assert.equal(lastSbn.props.text1, 'Enregistrement...');
lastSbn = null;
holdService = false;
heldCallbacks.shift()('disk error');
flush();
assert.notEqual(lastSbn, null, 'Error SBN emitted when background save failed');
assert.equal(lastSbn.type, 'errorNotification');
assert.equal(lastSbn.props.text1, 'Échec de l’enregistrement');

// 8d. Concurrency: callbacks in syncFromService are queued and all invoked
let pendingServiceCb = null;
let getRequests = 0;
resident.service.request = (op, args, cb) => {
    if (op === 'get') {
        getRequests++;
        pendingServiceCb = cb;
    } else if (op === 'set') {
        queue.push(() => {
            cb('set error');
        });
    }
};
// Trigger first failure which calls syncFromService(cb1)
hostEvents.message({
    source: view,
    data: {
        type: 'aa-request',
        token: 'fixture-token',
        action: 'set',
        payload: { key: 'touch', value: true }
    }
});
flush();
assert.equal(getRequests, 1, 'First get request started');
assert.notEqual(pendingServiceCb, null, 'Service get request in flight');

// Trigger a second event while get is still in flight (calls syncFromService without a second get request)
resident.reconnected();
assert.equal(getRequests, 1, 'Second sync call queued without duplicate request');

// Now resolve the in-flight get request
let broadcastCount = 0;
viewEvents.message = [event => {
    if (event.data && event.data.type === 'aa-response') {
        broadcastCount++;
    }
}];
pendingServiceCb(null, { success: true, settings: Object.assign({}, savedSettings) });
flush();
assert.equal(broadcastCount >= 1, true, 'Queued sync completed and broadcast state');

// 8e. Initial get failure broadcasts error to view even when cachedSettings is null
{
    let errorReceived = null;
    const testView = {
        location: { hash: '#mzdgui=err-token' },
        addEventListener: () => {},
        removeEventListener: () => {},
        postMessage: data => {
            if (data.type === 'aa-response') {
                errorReceived = data.error;
            }
        }
    };
    let freshHostEvents;
    const testHostContext = {
        window: {
            MzdGuiResidents: {
                register(id, fn) {
                    fn({
                        view: () => ({ source: testView, token: 'err-token' }),
                        onMessage: fn => { freshHostEvents = fn; },
                        onViewClose: () => {},
                        onDispose: () => {},
                        onServiceReady: () => {},
                        service: {
                            request(op, args, cb) {
                                if (op === 'get') {
                                    cb('Initial connection failed');
                                }
                            }
                        }
                    });
                }
            }
        },
        document: hostContext.document
    };
    vm.runInNewContext(fs.readFileSync(path.join(aaRoot, 'assets/resident.js'), 'utf8'), testHostContext);
    freshHostEvents({
        source: testView,
        data: { type: 'aa-request', token: 'err-token', action: 'get' }
    });
    assert.equal(errorReceived, 'Initial connection failed', 'Error broadcast when cachedSettings is null');
}

// 8f. NativeMenu check is exception-safe when framework is temporarily undefined
assert.doesNotThrow(() => {
    const origFw = host.framework;
    delete host.framework;
    if (host.refresh) { host.refresh(); }
    host.framework = origFw;
}, 'check does not throw when framework is undefined');

// 9. Re-entering view serves state immediately from resident cache
let reloadedState = null;
viewEvents.message = [event => {
    if (event.data && event.data.type === 'aa-response') {
        reloadedState = event.data.state;
    }
}];
hostEvents.message({
    source: view,
    data: {
        type: 'aa-request',
        token: 'fixture-token',
        action: 'get'
    }
});
flush();
assert.notEqual(reloadedState, null, 'Resident immediately returned cached state');
assert.equal(reloadedState.hud_maneuver_max_distance_m, 1000);
assert.equal(reloadedState.touch, false);

hostEvents.unload();
flush();

console.log('ANDROID_AUTO_VIEW_PASSED: MZD Connect styling, OEM reboot icon and confirmation dialog, No/Yes reboot behavior, modal dismissal and focus restoration, saved-change reboot notice, settings navigation, SBN system toast and cleanup.');
