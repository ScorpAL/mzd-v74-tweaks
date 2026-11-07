/* Local prototype adapter using the same OEM List2 factory as Applications. */
(function (global) {
    'use strict';
    function create(options) {
        options = options || {};
        var session = null, selection = null, dialogAssetsReady = false, dialogAssetsLoading = false;
        var dialogAssetCallbacks = [];
        function finishDialogAssets(error) {
            var callbacks = dialogAssetCallbacks, i;
            dialogAssetCallbacks = [];
            dialogAssetsLoading = false;
            dialogAssetsReady = !error;
            for (i = 0; i < callbacks.length; i += 1) {
                callbacks[i](error || '');
            }
        }
        function loadDialogStyle(path, callback) {
            var link = document.createElement('link'), head = document.getElementsByTagName('head')[0], complete = false;
            if (!head) {
                callback('Mazda dialog styles are unavailable.');
                return;
            }
            link.rel = 'stylesheet';
            link.href = path;
            link.onload = function () {
                if (complete) { return; }
                complete = true;
                callback('');
            };
            link.onerror = function () {
                if (complete) { return; }
                complete = true;
                callback('Failed to load Mazda dialog styles.');
            };
            head.appendChild(link);
        }
        function loadDialogScript(path, kind, name, callback) {
            var fw = global.framework, script = document.createElement('script'), head = document.getElementsByTagName('head')[0];
            var original, wrapper, registered = false, complete = false;
            if (!head) {
                callback('Mazda dialog scripts are unavailable.');
                return;
            }
            original = kind === 'template' ? fw.registerTmpltLoaded : fw.registerCtrlLoaded;
            wrapper = function (registeredName) {
                if (registeredName === name) {
                    registered = true;
                    if (kind === 'template') {
                        fw._templatesLoaded[name] = fw._templatesLoaded[name] || {isLoaded: true, nameCounter: 0};
                    } else {
                        fw._controlsLoaded[name] = fw._controlsLoaded[name] || {isLoaded: true, nameCounter: 0};
                    }
                    return;
                }
                return original.apply(this, arguments);
            };
            if (typeof original !== 'function') {
                callback('Mazda dialog registration is unavailable.');
                return;
            }
            fw[kind === 'template' ? 'registerTmpltLoaded' : 'registerCtrlLoaded'] = wrapper;
            function restoreRegistration() {
                var method = kind === 'template' ? 'registerTmpltLoaded' : 'registerCtrlLoaded';
                if (fw[method] === wrapper) { fw[method] = original; }
            }
            function finish(error) {
                if (complete) { return; }
                complete = true;
                restoreRegistration();
                if (!error && !registered) { error = 'Mazda dialog component did not register: ' + name; }
                callback(error || '');
            }
            script.onload = function () { finish(''); };
            script.onerror = function () { finish('Failed to load Mazda dialog component: ' + name); };
            script.onreadystatechange = function () {
                if (script.readyState === 'loaded' || script.readyState === 'complete') { finish(''); }
            };
            script.src = path;
            head.appendChild(script);
        }
        function ensureDialogAssets(callback) {
            var fw = global.framework, styles, i;
            if (dialogAssetsReady) {
                callback('');
                return;
            }
            dialogAssetCallbacks.push(callback);
            if (dialogAssetsLoading) { return; }
            if (fw._templatesLoaded && fw._templatesLoaded.Dialog3Tmplt && fw._templatesLoaded.Dialog3Tmplt.isLoaded &&
                    fw._controlsLoaded && fw._controlsLoaded.Dialog3Ctrl && fw._controlsLoaded.Dialog3Ctrl.isLoaded &&
                    fw._controlsLoaded.ButtonCtrl && fw._controlsLoaded.ButtonCtrl.isLoaded &&
                    typeof global.Dialog3Tmplt === 'function') {
                dialogAssetsLoading = true;
                finishDialogAssets('');
                return;
            }
            dialogAssetsLoading = true;
            styles = [
                '/jci/gui/common/controls/Dialog3/css/Dialog3Ctrl.css',
                '/jci/gui/common/controls/Button/css/ButtonCtrl.css'
            ];
            function loadScripts() {
                var scripts = [
                    {path: '/jci/gui/common/controls/Button/js/ButtonCtrl.js', kind: 'control', name: 'ButtonCtrl', key: 'common/controls/Button'},
                    {path: '/jci/gui/common/controls/Dialog3/js/Dialog3Ctrl.js', kind: 'control', name: 'Dialog3Ctrl', key: 'common/controls/Dialog3'},
                    {path: '/jci/gui/common/templates/Dialog3/js/Dialog3Tmplt.js', kind: 'template', name: 'Dialog3Tmplt'}
                ];
                function nextScript(index) {
                    var item;
                    if (index >= scripts.length) {
                        finishDialogAssets('');
                        return;
                    }
                    item = scripts[index];
                    loadDialogScript(item.path, item.kind, item.name, function (error) {
                        if (error) {
                            finishDialogAssets(error);
                            return;
                        }
                        if (item.key && fw._processedFilePaths) { fw._processedFilePaths[item.key] = true; }
                        nextScript(index + 1);
                    });
                }
                nextScript(0);
            }
            function nextStyle(index) {
                if (index >= styles.length) {
                    loadScripts();
                    return;
                }
                loadDialogStyle(styles[index], function (error) {
                    if (error) {
                        finishDialogAssets(error);
                        return;
                    }
                    nextStyle(index + 1);
                });
            }
            nextStyle(0);
        }
        function send(type, value) {
            if (session) {
                session.frame.contentWindow.postMessage({
                    type: type,
                    token: session.token,
                    index: value
                }, '*');
            }
        }
        function destroyList() {
            if (session && session.control) {
                try { global.framework.destroyControl(session.control); } catch (ignore) {}
                session.control = null;
            }
        }
        function removeDialogTemplate() {
            var dialog;
            if (!session || !session.dialogTemplate) { return; }
            dialog = session.dialogTemplate;
            if (typeof dialog.cleanUp === 'function') { dialog.cleanUp(); }
            if (dialog.divElt && dialog.divElt.parentNode) {
                dialog.divElt.parentNode.removeChild(dialog.divElt);
            }
            session.dialogTemplate = null;
            session.dialogSignature = '';
        }
        function destroyDialog(restoreFocus) {
            if (!session) { return; }
            session.dialogRequest += 1;
            session.pendingDialog = null;
            removeDialogTemplate();
            if (session.dialogContainer && session.dialogContainer.parentNode) {
                session.dialogContainer.parentNode.removeChild(session.dialogContainer);
            }
            session.dialogContainer = null;
            if (restoreFocus && session.dialogCapture && session.control) {
                session.control.restoreContext(session.dialogCapture);
                session.control.handleControllerEvent('acceptFocusInit');
            }
            session.dialogCapture = null;
        }
        function showDialog(frame, token, spec) {
            var fw = global.framework, signature, request;
            if (!session || session.frame !== frame || session.token !== token) { return; }
            if (!spec) {
                destroyDialog(true);
                return;
            }
            if (typeof spec.text !== 'string' || !spec.buttons || spec.buttons.length !== 2) {
                throw new Error('Invalid confirmation dialog.');
            }
            signature = JSON.stringify(spec);
            if (session.dialogTemplate && session.dialogSignature === signature) { return; }
            if (!session.dialogContainer) {
                session.dialogCapture = session.control.getContextCapture();
                session.control.handleControllerEvent('lostFocus');
                session.dialogContainer = document.createElement('div');
                session.dialogContainer.style.cssText = 'position:absolute;left:0;top:0;width:800px;height:480px;z-index:20000;';
                document.body.appendChild(session.dialogContainer);
            }
            request = ++session.dialogRequest;
            session.pendingDialog = spec;
            ensureDialogAssets(function (error) {
                var button, template;
                if (!session || session.frame !== frame || session.token !== token || session.dialogRequest !== request) { return; }
                if (error) {
                    destroyDialog(true);
                    send('aa-native-error', error);
                    return;
                }
                button = spec.buttons[0];
                try {
                    template = fw.instantiateTemplate('system', session.dialogContainer, 'Dialog3Tmplt', {
                        Dialog3Ctrl: {
                            contentStyle: 'style02',
                            fullScreen: true,
                            initialFocus: 0,
                            text1: spec.text,
                            buttonConfig: {
                                button1: {appData: button.value, label: button.label, labelId: button.labelId},
                                button2: {
                                    appData: spec.buttons[1].value,
                                    label: spec.buttons[1].label,
                                    labelId: spec.buttons[1].labelId
                                }
                            },
                            defaultSelectCallback: function (source, value) {
                                if (session && session.frame === frame && session.token === token && session.dialogRequest === request) {
                                    send('aa-native-dialog-select', value);
                                }
                            }
                        }
                    });
                    if (!template || !template.dialog3Ctrl) { throw new Error('Mazda confirmation dialog could not be created.'); }
                    session.dialogTemplate = template;
                    session.dialogSignature = signature;
                    session.pendingDialog = null;
                } catch (failure) {
                    destroyDialog(true);
                    send('aa-native-error', String(failure.message || failure));
                }
            });
        }
        function close() {
            var old = session, fw = global.framework, app;
            if (!old) { return; }
            global.clearTimeout(selection);
            selection = null;
            destroyDialog(false);
            destroyList();
            session = null;
            if (typeof options.onClose === 'function') {
                try { options.onClose(); } catch (ignore) {}
            }
            if (fw && fw.sendEventToMmui === old.backWrapper) {
                fw.sendEventToMmui = old.originalSend;
            }
            if (old.container.parentNode) {
                old.container.parentNode.removeChild(old.container);
            }
            old.frame.style.display = old.display;
            old.root.style.cssText = old.css;
            old.root.className = old.className;
            if (fw && typeof fw.getCurrentApp === 'function' && fw.getCurrentApp() === 'system' && fw.getCurrCtxtId() === 'Applications') {
                app = fw.getAppInstance('system');
                if (!app._currentContextTemplate || !app._currentContextTemplate.divElt || app._currentContextTemplate.divElt.style.visibility !== 'hidden') {
                    if (app._currentContextTemplate && app._currentContextTemplate.list2Ctrl) {
                        app._currentContextTemplate.list2Ctrl.setLineNumbers();
                    }
                }
                if (fw.common && fw.common.setSbNameId) {
                    fw.common.setSbNameId('system', 'Applications');
                }
            }
        }
        function attach(frame, token) {
            var fw = global.framework, root = frame.parentNode, container, originalSend;
            if (session && session.frame === frame && session.token === token) { return; }
            close();
            if (!fw || typeof fw.instantiateControl !== 'function' || typeof fw.destroyControl !== 'function') {
                throw new Error('Mazda list factory unavailable.');
            }
            container = document.createElement('div');
            container.className = 'TemplateWithStatusLeft List2Tmplt';
            container.style.cssText = 'position:absolute;left:0;top:0;width:740px;height:416px;';
            session = {
                frame: frame,
                source: frame.contentWindow,
                token: token,
                root: root,
                container: container,
                control: null,
                page: '',
                signature: '',
                dialogContainer: null,
                dialogTemplate: null,
                pendingDialog: null,
                dialogRequest: 0,
                dialogCapture: null,
                dialogSignature: '',
                css: root.style.cssText,
                className: root.className,
                display: frame.style.display,
                originalSend: fw.sendEventToMmui
            };
            frame.style.display = 'none';
            root.style.cssText = 'position:absolute;left:60px;top:64px;width:740px;height:416px;z-index:7;background:transparent;overflow:visible;';
            root.className = '';
            root.appendChild(container);
            ensureDialogAssets(function () {});
            originalSend = session.originalSend;
            session.backWrapper = function (uia, event) {
                if (session && event === 'Global.GoBack' && fw.getCurrentApp() === 'system' && fw.getCurrCtxtId() === 'Applications') {
                    session.frame.contentWindow.postMessage({
                        type: 'mzd-gui-input',
                        token: session.token,
                        action: 'back',
                        phase: 'step'
                    }, '*');
                    return;
                }
                return originalSend.apply(this, arguments);
            };
            fw.sendEventToMmui = session.backWrapper;
        }
        function render(frame, token, menu) {
            var fw = global.framework, items = [], i, row, captured, signature, current, oldPage;
            if (!menu || typeof menu.title !== 'string' || !menu.rows || menu.rows.length > 202) {
                throw new Error('Invalid native menu.');
            }
            attach(frame, token);
            if (typeof options.onOpen === 'function') {
                try { options.onOpen(); } catch (ignore) {}
            }
            current = session;
            if (fw.common && fw.common.setSbName) {
                fw.common.setSbName(menu.title.replace(/[.]png/gi, ''));
            }
            for (i = 0; i < menu.rows.length; i += 1) {
                row = menu.rows[i];
                items.push({
                    appData: { aaIndex: i },
                    text1Id: null,
                    text1: row.label,
                    itemStyle: row.itemStyle || (row.checkable ? 'style03' : row.detail ? 'style06' : 'style01'),
                    checked: row.checked === true,
                    value: row.value != null ? row.value : (row.checked ? 1 : 2),
                    image1: row.checkable ? (row.radio ? 'radio' : 'tick') : (row.image1 || ''),
                    label1Id: null,
                    label1: row.detail || '',
                    hasCaret: row.caret === true,
                    disabled: row.disabled === true
                });
            }
            signature = JSON.stringify(items);
            oldPage = session.page;
            if (session.control && oldPage === menu.page && session.signature === signature) {
                return;
            }
            if (session.control && oldPage === menu.page) {
                captured = session.control.getContextCapture();
                session.control.setDataListAndUpdateItems({
                    itemCountKnown: true,
                    itemCount: items.length,
                    items: items,
                    vuiSupport: false
                });
                if (captured.focussedItem >= items.length) {
                    captured.focussedItem = 0;
                    captured.topItem = 0;
                }
                session.control.restoreContext(captured);
            } else {
                global.clearTimeout(selection);
                destroyList();
                session.container.innerHTML = '';
                session.control = fw.instantiateControl('system', session.container, 'List2Ctrl', {
                    titleConfiguration: 'noTitle',
                    numberedList: true,
                    smallItemText: true,
                    focussedItem: menu.index || 0,
                    dataList: {
                        itemCountKnown: true,
                        itemCount: items.length,
                        items: items,
                        vuiSupport: false
                    },
                    selectCallback: function (source, data) {
                        if (session !== current || source !== current.control || !data) { return; }
                        global.clearTimeout(selection);
                        selection = global.setTimeout(function () {
                            if (session === current && current.control === source) {
                                send('aa-native-select', data.aaIndex);
                            }
                        }, 0);
                    }
                });
                session.control.handleControllerEvent('acceptFocusInit');
            }
            session.page = menu.page;
            session.signature = signature;
        }
        function input(frame, token, action, phase) {
            var control, event, capture;
            if (!session || session.frame !== frame || session.token !== token || !session.control) { return; }
            if (session.pendingDialog && !session.dialogTemplate) { return; }
            control = session.dialogTemplate || session.control;
            function dispatch(controllerEvent) {
                var common = global.framework.common;
                var leftBtn = common && common.leftBtn;
                var response;
                if (session.dialogTemplate) {
                    return control.handleControllerEvent(controllerEvent);
                }
                if (leftBtn && leftBtn.btnInstance && leftBtn.btnInstance.hasFocus) {
                    response = leftBtn.handleControllerEvent(controllerEvent);
                    if (response === 'giveFocusRight') {
                        response = control.handleControllerEvent('acceptFocusFromLeft');
                        if (response === 'consumed') {
                            leftBtn.handleControllerEvent('lostFocus');
                        }
                    }
                    return response;
                }
                response = control.handleControllerEvent(controllerEvent);
                if (response === 'giveFocusLeft' && leftBtn) {
                    leftBtn.handleControllerEvent('acceptFocusFromRight');
                    control.handleControllerEvent('lostFocus');
                }
                return response;
            }
            if (action === 'rotateRight' || action === 'rotateLeft') {
                if (phase === 'release') { return; }
                event = action === 'rotateRight' ? 'cw' : 'ccw';
            } else {
                if (['up', 'down', 'left', 'right', 'select'].indexOf(action) < 0) { return; }
                if (phase === 'step') {
                    dispatch(action + 'Start');
                    event = action;
                } else {
                    event = phase === 'press' ? action + 'Start' : action;
                }
            }
            dispatch(event);
            if (session.dialogTemplate) { return; }
            capture = control.getContextCapture();
            send('aa-native-focus', capture.focussedItem);
        }
        return {
            render: render,
            input: input,
            dialog: showDialog,
            close: close,
            owns: function (source, token) {
                return session && session.source === source && session.token === token;
            },
            check: function () {
                if (session && (!document.documentElement.contains(session.frame) || !global.framework || typeof global.framework.getCurrentApp !== 'function' || global.framework.getCurrentApp() !== 'system' || global.framework.getCurrCtxtId() !== 'Applications')) {
                    close();
                }
            }
        };
    }

    global.MzdGuiResidents.register('android-auto', function (context) {
        'use strict';
        var refreshTimer = null;
        function startPolling() {
            if (!refreshTimer) {
                refreshTimer = global.setInterval(function () {
                    nativeMenu.check();
                }, 500);
            }
        }
        function stopPolling() {
            if (refreshTimer) {
                global.clearInterval(refreshTimer);
                refreshTimer = null;
            }
        }

        var settingsViewOpen = false, settingsViewLeft = false, settingsSavedInView = false;
        var rebootNoticeShown = false, rebootNoticeText = 'Reboot to apply settings';

        function beginSettingsView() {
            if (settingsViewOpen) { return; }
            settingsViewOpen = true;
            settingsViewLeft = false;
            settingsSavedInView = false;
            rebootNoticeShown = false;
            rebootNoticeText = 'Reboot to apply settings';
        }

        function showRebootNotice() {
            if (rebootNoticeShown || !settingsSavedInView) { return; }
            showSbn(rebootNoticeText, false);
            rebootNoticeShown = true;
        }

        function endSettingsView() {
            settingsViewOpen = false;
            settingsViewLeft = true;
            if (!savePending) { showRebootNotice(); }
        }

        var nativeMenu = create({
            onOpen: function () {
                beginSettingsView();
                startPolling();
            },
            onClose: function () {
                stopPolling();
                endSettingsView();
            }
        });
        var hostEnded = false;
        var cachedSettings = null, cachedLoaded = false;
        var queue = [], inFlight = false, syncing = false;
        var syncCallbacks = [];
        var lastSavingMessage = '', lastSavedMessage = '', lastErrorMessage = '', savePending = false, savingNoticeShown = false;

        function showSbn(text, isError) {
            var fw = global.framework;
            if (fw && fw.common && typeof fw.common.startTimedSbn === 'function') {
                fw.common.startTimedSbn('androidauto', 'AASettingsNotification', isError ? 'errorNotification' : 'typeD', {
                    sbnStyle: 'Style02',
                    imagePath1: 'common/images/icons/IcnSbnApps.png',
                    text1: text
                });
            }
        }

        function clearSaveNotice() {
            lastSavingMessage = '';
            lastSavedMessage = '';
            lastErrorMessage = '';
            savePending = false;
            savingNoticeShown = false;
        }

        function frameToken(source) {
            var current = context.view();
            return current && current.source === source ? current.token : '';
        }

        function broadcastState(error) {
            var current = context.view();
            if (current && current.source && (cachedSettings || error)) {
                try {
                    current.source.postMessage({
                        type: 'aa-response',
                        token: current.token,
                        state: cachedSettings,
                        error: error || ''
                    }, '*');
                } catch (ignore) {}
            }
        }

        function syncFromService(cb) {
            if (cb) { syncCallbacks.push(cb); }
            if (syncing) { return; }
            syncing = true;
            context.service.request('get', {}, function (error, result) {
                var cbs, i;
                syncing = false;
                if (!error && result && result.settings) {
                    cachedSettings = result.settings;
                    cachedLoaded = true;
                    broadcastState('');
                } else if (error) {
                    broadcastState(error);
                }
                cbs = syncCallbacks;
                syncCallbacks = [];
                for (i = 0; i < cbs.length; i += 1) {
                    try {
                        cbs[i](error, result);
                    } catch (ignore) {}
                }
            });
        }

        function hasQueuedKey(key) {
            var i;
            for (i = 0; i < queue.length; i += 1) {
                if (queue[i].key === key) { return true; }
            }
            return false;
        }

        function drainQueue() {
            if (hostEnded || inFlight || queue.length === 0) { return; }
            var next = queue.shift();
            inFlight = true;
            context.service.request('set', { key: next.key, value: next.value }, function (error, result) {
                inFlight = false;
                if (error) {
                    queue = [];
                    if (savePending) {
                        showSbn(lastErrorMessage || 'Failed to save settings', true);
                        clearSaveNotice();
                    }
                    if (settingsViewLeft) { showRebootNotice(); }
                    syncFromService(function () {
                        broadcastState(error);
                    });
                    return;
                }
                if (result && result.settings) {
                    for (var k in result.settings) {
                        if (Object.prototype.hasOwnProperty.call(result.settings, k)) {
                            if (!hasQueuedKey(k)) {
                                cachedSettings[k] = result.settings[k];
                            }
                        }
                    }
                }
                settingsSavedInView = true;
                broadcastState('');
                if (queue.length > 0) {
                    drainQueue();
                } else {
                    if (savePending) {
                        if (settingsViewLeft) {
                            showRebootNotice();
                        } else {
                            showSbn(lastSavedMessage || 'Settings saved', false);
                        }
                        clearSaveNotice();
                    }
                }
            });
        }

        function receive(event) {
            var data = event.data, token = frameToken(event.source), frames, frame, i;
            if (data && data.type === 'aa-native-release') {
                if ((token && data.token === token) || (nativeMenu && nativeMenu.owns(event.source, data.token))) {
                    nativeMenu.close();
                    if (inFlight || queue.length > 0) {
                        lastSavedMessage = data.savedMessage || 'Settings saved';
                        lastErrorMessage = data.errorMessage || 'Failed to save settings';
                        savePending = true;
                        if (data.savingMessage && (!savingNoticeShown || lastSavingMessage !== data.savingMessage)) {
                            showSbn(data.savingMessage, false);
                            lastSavingMessage = data.savingMessage;
                            savingNoticeShown = true;
                        }
                    }
                }
                return;
            }
            if (!token || !data || data.token !== token) { return; }
            if (data.type === 'aa-native-render' || data.type === 'aa-native-input' || data.type === 'aa-native-dialog') {
                frames = document.getElementsByTagName('iframe');
                for (i = 0; i < frames.length; i += 1) {
                    if (frames[i].contentWindow === event.source) { frame = frames[i]; }
                }
                if (!frame) { return; }
                try {
                    if (data.type === 'aa-native-render') {
                        nativeMenu.render(frame, token, data.menu);
                    } else if (data.type === 'aa-native-input') {
                        nativeMenu.input(frame, token, data.action, data.phase);
                    } else {
                        nativeMenu.dialog(frame, token, data.dialog);
                    }
                } catch (failure) {
                    nativeMenu.close();
                    event.source.postMessage({
                        type: 'aa-native-error',
                        token: token,
                        message: String(failure.message || failure)
                    }, '*');
                }
                return;
            }
            if (data.type === 'aa-request') {
                if (data.action === 'get') {
                    if (cachedLoaded && cachedSettings) {
                        broadcastState('');
                    } else {
                        syncFromService();
                    }
                    return;
                }
                if (data.action === 'reboot') {
                    context.service.request('reboot', {}, function (error) {
                        if (error) {
                            showSbn(data.payload && data.payload.errorMessage || 'Hold NAV + MUTE to reboot', false);
                        }
                    });
                    return;
                }
                if (data.action === 'set' && data.payload && data.payload.key) {
                    beginSettingsView();
                    lastSavedMessage = data.payload.savedMessage || 'Settings saved';
                    lastErrorMessage = data.payload.errorMessage || 'Failed to save settings';
                    rebootNoticeText = data.payload.rebootNotice || 'Reboot to apply settings';
                    if (!savePending) {
                        savePending = true;
                        lastSavingMessage = data.payload.savingMessage || 'Saving settings...';
                        showSbn(lastSavingMessage, false);
                        savingNoticeShown = true;
                    }
                    if (!cachedSettings) { cachedSettings = {}; }
                    cachedSettings[data.payload.key] = data.payload.value;
                    var found = false;
                    for (i = 0; i < queue.length; i += 1) {
                        if (queue[i].key === data.payload.key) {
                            queue[i].value = data.payload.value;
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        queue.push({ key: data.payload.key, value: data.payload.value });
                    }
                    drainQueue();
                }
            }
        }
        context.onMessage(receive);
        context.onViewClose(function () {
            nativeMenu.close();
            stopPolling();
            endSettingsView();
        });
        context.onDispose(function () {
            hostEnded = true;
            nativeMenu.close();
            stopPolling();
            endSettingsView();
        });
        context.onServiceReady(function () {
            if (cachedLoaded) {
                syncFromService();
            }
        });
    });
}(window));
