/* CMU Opera 12-compatible UI. Manifests are data; only run.sh owns state. */
(function () {
    "use strict";
    var config = window.installerConfig, frame = document.getElementById("transport");
    var pending = {}, requestId = 0, connected = false, manager = null;
    var tweaks = [], selectedGroup = "", selected = null, scanning = false;
    var restartRequired = false, failedStatusName = "";
    var operating = false, closing = false, locked = false, dialogMode = "", returnFocusId = "", accepted = false;
    var detailView = 0;
    function el(id) { return document.getElementById(id); }
    function text(id, value) { el(id).textContent = value; }
    function show(id, visible) { el(id).className = visible ? el(id).className.replace(/\bhidden\b/g, "") : el(id).className.replace(/\bhidden\b/g, "") + " hidden"; }
    function clear(node) { while (node.firstChild) node.removeChild(node.firstChild); }
    function setDialogMode(mode) {
        dialogMode=mode;
        if (mode!=="details") show("restore-action",false);
    }
    function trim(value) { return String(value || "").replace(/^\s+|\s+$/g, ""); }
    function supported(item, action) { return item.manifest.actions.indexOf(action) !== -1; }
    function resultError(result) {
        if (!result || !result.started) return result && result.startError ? result.startError : "Process did not start.";
        if (result.signal) return "Process stopped by signal " + result.signal + ". Outcome may be unknown.";
        if (result.exitCode !== 0) return trim(result.stderr) || trim(result.stdout) || "Worker failed (exit " + result.exitCode + ").";
        return "";
    }
    // The existing native adapter represents output bytes as JSON \u00xx.
    // Decode UTF-8 here so non-ASCII manifest text remains readable as well.
    function outputText(value) { try { return decodeURIComponent(escape(value)); } catch (ignore) { return value; } }
    var shell = {
        exec: function (program, args, callback) {
            var id = ++requestId;
            pending[id] = callback;
            frame.contentWindow.postMessage({type:"shell-exec",token:config.token,id:id,program:program,args:args}, config.origin);
        }
    };
    function call(args, callback) { shell.exec("/bin/sh", ["./installer.sh"].concat(args), callback); }
    var cpuTotal = "0", cpuIdle = "0", metricsPending = false;
    function updateMetrics() {
        // Never enqueue telemetry behind status scans or a modifying action.
        if (!connected || closing || scanning || operating || metricsPending) return;
        metricsPending = true;
        call(["metrics", cpuTotal, cpuIdle], function (error, result) {
            metricsPending = false;
            var node = el("system-info"); clear(node);
            if (error || resultError(result)) { node.textContent = "System information unavailable"; return; }
            var lines = trim(result.stdout).split("\n"), parts, value, i;
            for (i = 0; i < lines.length; i++) {
                parts = lines[i].split("\t"); value = "";
                if (parts[0] === "cpu" && /^\d+$/.test(parts[1]) && /^\d+$/.test(parts[2])) {
                    cpuTotal = parts[1]; cpuIdle = parts[2];
                    value = "CPU: " + (/^\d+$/.test(parts[3]) ? parts[3] + "%" : "--");
                } else if (parts[0] === "disk" && /^\d+$/.test(parts[2])) {
                    if (parts[1] === "/") value = "System: " + parts[2] + "% free";
                    else if (parts[1] === "/tmp/mnt/resources" || parts[1] === "/mnt/resources") value = "Resources: " + parts[2] + "% free";
                }
                if (value) { var span = document.createElement("span"); span.textContent = value; node.appendChild(span); }
            }
            if (!node.firstChild) node.textContent = "System information unavailable";
        });
    }
    function footer(message) { text("footer-status", message); }
    function label(state) {
        if (state === "installed") return "Installed";
        if (state === "uninstalled") return "Not installed";
        if (state === "unavailable") return "Unavailable";
        if (state === "broken") return "Broken installation";
        if (state === "error") return "Status error";
        if (state === "command") return "Command";
        return "Checking status...";
    }
    function itemLabel(item) {return item.manifest.type==="command" && item.state==="uninstalled" ? "Ready" : label(item.state);}
    function controls() {
        el("refresh").disabled = !accepted || scanning || operating || closing || locked;
        el("exit").disabled = operating || closing;
        el("restore-action").disabled = scanning || locked || operating || closing;
        if (dialogMode === "restart") el("action").disabled = scanning || locked || operating || closing;
        var nodes = el("tabs").getElementsByTagName("button"), i;
        for (i = 0; i < nodes.length; i++) nodes[i].disabled = operating || closing;
        nodes = el("cards").getElementsByTagName("button");
        for (i = 0; i < nodes.length; i++) nodes[i].disabled = operating || closing;
    }
    function updateCard(item) {
        if (!item.button) return;
        item.dot.className = "dot " + item.state;
        item.statusNode.textContent = itemLabel(item);
        item.button.setAttribute("aria-label", item.name + ": " + itemLabel(item));
    }
    function groups() {
        var found = [], i;
        for (i = 0; i < tweaks.length; i++) if (found.indexOf(tweaks[i].group) === -1) found.push(tweaks[i].group);
        return found.sort();
    }
    function groupName(group) { return group.charAt(0).toUpperCase() + group.substring(1); }
    function renderTabs() {
        var node = el("tabs"), all = groups(); clear(node);
        if (all.indexOf(selectedGroup) === -1) selectedGroup = all[0] || "";
        for (var i = 0; i < all.length; i++) (function (group) {
            var count = 0;
            for (var j = 0; j < tweaks.length; j++) if (tweaks[j].group === group) count++;
            var button = document.createElement("button");
            button.className = "tab" + (group === selectedGroup ? " selected" : "");
            button.textContent = groupName(group) + " (" + count + ")";
            button.setAttribute("role", "tab"); button.setAttribute("aria-selected", group === selectedGroup ? "true" : "false");
            button.onclick = function () {
                selectedGroup = group;
                // Keep the category buttons in the DOM so controller focus survives.
                var tabs = el("tabs").getElementsByTagName("button");
                for (var k = 0; k < tabs.length; k++) {
                    tabs[k].className = tabs[k] === button ? "tab selected" : "tab";
                    tabs[k].setAttribute("aria-selected", tabs[k] === button ? "true" : "false");
                }
                renderCards(); button.focus();
            };
            node.appendChild(button);
        }(all[i]));
        controls();
    }
    function renderCards() {
        var node = el("cards"); clear(node);
        show("empty", !tweaks.length);
        text("empty", "No tweaks found in the tweaks folder.");
        for (var i = 0; i < tweaks.length; i++) {
            var item = tweaks[i]; item.button = null;
            if (item.group !== selectedGroup) continue;
            var button = document.createElement("button"), dot = document.createElement("i"), name = document.createElement("span"), state = document.createElement("span");
            button.className = "tweak"; button.id = "tweak-" + item.id;
            name.className = "tweak-name"; name.textContent = item.name;
            state.className = "tweak-status";
            button.appendChild(dot); button.appendChild(name); button.appendChild(state);
            (function (tweak) { button.onclick = function () { openDetails(tweak); }; }(item));
            item.button = button; item.dot = dot; item.statusNode = state;
            node.appendChild(button); updateCard(item);
        }
        el("content").scrollTop = 0; controls();
    }
    function parseManifest(id, raw) {
        var m = {}, lines = raw.split("\n"), fields = "contract_version id name description version type group firmware entrypoint actions target oem_backup_md5 lock_group status_scope reboot_required requires conflicts progress confirmation refresh_all reset_entrypoint".split(" ");
        for (var n = 0; n < lines.length; n++) {
            var line = lines[n].replace(/\r$/, "");
            if (/[\x00-\x1f\x7f]/.test(line)) throw new Error("Manifest contains control characters.");
            if (!trim(line) || line.charAt(0) === "#") continue;
            var at = line.indexOf("="), key = line.substring(0, at);
            if (at < 0 || fields.indexOf(key) === -1) throw new Error("Invalid manifest field.");
            if (Object.prototype.hasOwnProperty.call(m,key)) throw new Error("Duplicate manifest field: " + key);
            m[key] = line.substring(at + 1);
        }
        var required = "contract_version id name description version type group firmware entrypoint actions status_scope reboot_required requires conflicts".split(" ");
        for (var r = 0; r < required.length; r++) if (!Object.prototype.hasOwnProperty.call(m,required[r])) throw new Error("Missing manifest field: " + required[r]);
        if (m.contract_version !== "1") throw new Error("Unsupported manifest contract version.");
        m.contract_version = 1;
        if (m.reboot_required !== "true" && m.reboot_required !== "false") throw new Error("Invalid reboot_required value.");
        m.reboot_required = m.reboot_required === "true";
        if (m.progress !== undefined && m.progress !== "true" && m.progress !== "false") throw new Error("Invalid progress value.");
        m.progress = m.progress === "true";
        if (m.refresh_all !== undefined && m.refresh_all !== "true" && m.refresh_all !== "false") throw new Error("Invalid refresh_all value.");
        m.refresh_all = m.refresh_all === "true";
        if (m.reset_entrypoint !== undefined && m.reset_entrypoint !== "" && m.reset_entrypoint !== "reset.sh") throw new Error("Invalid reset entrypoint.");
        var lists = ["firmware","actions","requires","conflicts"];
        for (var l = 0; l < lists.length; l++) m[lists[l]] = trim(m[lists[l]]) ? trim(m[lists[l]]).split(/ +/) : [];
        if (!m || m.contract_version !== 1 || m.id !== id || typeof m.name !== "string" || !trim(m.name) || typeof m.description !== "string" || !Array.isArray(m.actions) || m.entrypoint !== "run.sh") throw new Error("Invalid manifest: expected contract version 1, matching id, name, description, actions and entrypoint run.sh.");
        if (m.group !== undefined && (typeof m.group !== "string" || !trim(m.group))) throw new Error("Invalid manifest group.");
        return m;
    }
    function discover() {
        scanning = true; controls(); footer("Finding tweaks on USB...");
        call(["list"], function (error, result) {
            var problem = error || resultError(result);
            if (problem) { scanning = false; footer("Could not read tweaks"); showResult("Cannot read tweaks", String(problem), false, function () {}); controls(); return; }
            var ids = trim(result.stdout) ? trim(result.stdout).split(/\r?\n/) : [], index = 0;
            function nextManifest() {
                if (closing) return;
                if (index === ids.length) {
                    tweaks.sort(function (a,b) {return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : a.name.toLowerCase() > b.name.toLowerCase() ? 1 : 0;});
                    if (closing) return;
                    renderTabs(); renderCards(); refreshAll(); return;
                }
                var id = ids[index++];
                if (!/^[a-zA-Z0-9_-]+$/.test(id)) { nextManifest(); return; }
                footer("Reading " + id + "...");
                call(["manifest", id], function (error, result) {
                    var item = {id:id,name:id,group:"errors",manifest:{actions:[]},state:"error",error:"",invalid:false};
                    try {
                        var problem = error || resultError(result);
                        if (problem) throw new Error(String(problem));
                        if (result.stdoutTruncated) throw new Error("Manifest exceeds output limit.");
                        item.manifest = parseManifest(id, result.stdout); item.name = item.manifest.name;
                        item.group = item.manifest.group || "other"; item.state = "checking";
                    } catch (e) { item.error = String(e); item.invalid = true; }
                    tweaks.push(item); nextManifest();
                });
            }
            nextManifest();
        });
    }
    function checkStatus(item, callback) {
        if (item.invalid) { callback(); return; }
        if (!supported(item, "status")) {
            item.state = supported(item,"run") ? "command" : "error";
            item.error = item.state === "error" ? "Manifest has no status action." : "";
            updateCard(item); callback(); return;
        }
        item.state = "checking"; item.error = ""; updateCard(item);
        call(["action",item.id,"status"], function (error, result) {
            var problem = error || resultError(result), state = result ? trim(result.stdout) : "";
            if (!problem && !result.stdoutTruncated && !result.stderrTruncated && result.stdout === state + "\n" &&
                (state === "installed" || state === "uninstalled" || state === "unavailable" || state === "broken")) {
                if ((state === "unavailable" || state === "broken") && !trim(result.stderr)) {
                    item.state = "error"; item.error = "Worker returned " + state + " without a reason.";
                } else { item.state = state; item.error = trim(result.stderr); }
            }
            else { item.state = "error"; item.error = String(problem || "Unexpected status response: " + state); }
            if (result && (result.exitCode === 2 || result.signal)) {locked = true;failedStatusName = item.name;}
            updateCard(item); callback();
        });
    }
    function refreshAll() {
        scanning = true; controls();
        var ids = [], wanted = {}, items = [], i;
        for (i = 0; i < tweaks.length; i++) {
            var item = tweaks[i];
            if (item.invalid) continue;
            if (!supported(item,"status")) {
                item.state = supported(item,"run") ? "command" : "error";
                item.error = item.state === "error" ? "Manifest has no status action." : "";
                updateCard(item); continue;
            }
            ids.push(item.id); wanted["$" + item.id] = true; items.push(item);
            item.state = "checking"; item.error = ""; updateCard(item);
        }
        function finish(problem) {
            scanning = false; controls();
            footer(locked ? "Status failed: " + failedStatusName + ". Do NOT reboot." : problem ? "Could not read installation states" : tweaks.length + " tweaks - select a tweak");
            if (closing) return;
            if (dialogMode === "details") openDetails(selected);
            else if (!dialogMode && el("cards").firstChild) el("cards").firstChild.focus();
        }
        if (!ids.length) { finish(null); return; }
        footer("Reading installed tweaks...");
        call(["statuses",ids.join(" ")],function (error,result) {
            if (closing) {scanning=false;return;}
            var problem = error || resultError(result), rows = {}, j;
            if (result && (result.exitCode === 2 || result.signal)) {locked=true;failedStatusName="status scan";}
            try {
                if (problem) throw new Error(String(problem));
                if (result.stdoutTruncated || result.stderrTruncated || result.stdout.charAt(result.stdout.length-1) !== "\n") throw new Error("Incomplete status response.");
                var lines = result.stdout.slice(0,-1).split("\n");
                if (lines.length !== ids.length) throw new Error("Missing status entries.");
                for (j = 0; j < lines.length; j++) {
                    var fields = lines[j].split("\t"), key = "$" + fields[0];
                    if (fields.length !== 3 || !wanted[key] || rows[key] || !/^(installed|uninstalled|unavailable|broken|error)$/.test(fields[1])) throw new Error("Invalid status entry.");
                    if (/^(unavailable|broken|error)$/.test(fields[1]) && !trim(fields[2])) throw new Error("Status entry without a reason.");
                    rows[key] = {state:fields[1],reason:fields[2]};
                }
            } catch (e) {problem=String(e);}
            for (j = 0; j < items.length; j++) {
                var row = rows["$" + items[j].id];
                items[j].state = problem ? "error" : row.state;
                items[j].error = problem ? String(problem) : trim(row.reason);
                updateCard(items[j]);
            }
            finish(problem);
        });
    }
    function addMeta(key, value) {
        var row = document.createElement("div"), title = document.createElement("span"), content = document.createElement("span");
        row.className = "meta-row"; title.className = "meta-key"; title.textContent = key + ":";
        content.textContent = typeof value === "object" ? JSON.stringify(value) : String(value);
        row.appendChild(title); row.appendChild(content); el("dialog-meta").appendChild(row);
        return content;
    }
    function openDetails(item) {
        if (operating || closing || !item) return;
        var view=++detailView;
        show("restore-action",false);
        text("back","Back"); el("back").onclick=closeDialog;
        el("dialog-body").className = "bottom-info";
        selected = item; returnFocusId = "tweak-" + item.id; setDialogMode("details");
        text("dialog-title", item.name); el("dialog-dot").className = "dot " + item.state;
        text("dialog-state", itemLabel(item) + (item.error ? "\n" + item.error : ""));
        var description = item.manifest.description || "Manifest could not be loaded.";
        if (item.manifest.type === "patch" || item.manifest.type === "service" || item.manifest.type === "files") {
            if (item.state === "broken" || (item.state === "unavailable" && /target|patch|file|content|incompatible/i.test(item.error || ""))) description += "\n\nUse System > Restore originals, then retry.\nThis resets ALL patches on affected files.";
        }
        text("dialog-description", description);
        clear(el("dialog-meta")); text("dialog-output", "");
        // Present the manifest information needed to choose an action. Patch
        // hashes, lock names and internal file paths remain worker concerns.
        var versionMeta = item.manifest.version !== undefined ? addMeta("Version",item.manifest.version) : null;
        if (versionMeta && item.state === "installed" && item.manifest.type !== "command") {
            call(["package-info",item.id],function (error,result) {
                if (error || resultError(result) || dialogMode !== "details" || selected !== item) return;
                var info = trim(result.stdout).split("\t");
                if (info.length !== 2 || !/^[0-9]+\.[0-9]+\.[0-9]+$/.test(info[0])) return;
                if (info[0] !== item.manifest.version) versionMeta.textContent = info[0] + " installed / " + item.manifest.version + " on USB";
            });
        }
        if (item.manifest.firmware !== undefined) addMeta("Firmware",Array.isArray(item.manifest.firmware) ? item.manifest.firmware.join(", ") : item.manifest.firmware);
        if (item.manifest.type !== undefined) addMeta("Type",item.manifest.type);
        if (!item.invalid) addMeta("Category",groupName(item.group));
        if (item.manifest.reboot_required !== undefined) addMeta("Restart required",item.manifest.reboot_required ? "Yes (after exit)" : "No");
        show("back",true); show("action",true); show("result-ok",false); show("overlay",true);
        el("dialog-body").scrollTop = 0;
        var action = item.state === "installed" ? "uninstall" : item.state === "uninstalled" ? (supported(item,"run") ? "run" : "install") : item.state === "command" ? "run" : "status";
        text("action", action === "status" ? "Retry status" : action.charAt(0).toUpperCase() + action.substring(1));
        el("action").disabled = scanning || locked || item.invalid || !supported(item,action);
        el("back").disabled = false; el("back").focus();
        el("action").onclick = function () {
            if (el("action").disabled) return;
            if (action === "status") {
                scanning = true; controls(); el("action").disabled = true;
                checkStatus(item,function () {scanning=false;controls();openDetails(item);});
            } else if (action === "run" && item.manifest.confirmation) confirmRun(item);
            else perform(item,action);
        };
        // Inspect only the opened detail view, never the whole menu. Leave it
        // visible and preserve focus; eligibility adds a button, not a dialog.
        if (!scanning && !locked && !item.invalid && item.manifest.type==="patch" && item.state!=="installed" && supported(item,"install")) {
            call(["restore-check",item.id],function (error,result) {
                if (error || view!==detailView || dialogMode!=="details" || selected!==item || operating || closing || scanning || locked) return;
                var offer=originalRestoreOffer(result);
                if (!offer) {
                    var reason=error || resultError(result) || "The restore check returned an invalid response.";
                    text("dialog-description",description+"\n\nRestore original unavailable:\n"+String(reason));
                    return;
                }
                show("restore-action",true); el("restore-action").disabled=false;
                text("dialog-description",item.manifest.description+"\n\nRestore original resets ALL changes to this file.");
                el("restore-action").onclick=function () {
                    if (el("restore-action").disabled) return;
                    confirmOriginalRestore(item,offer.hash,offer.path,function () {openDetails(item);});
                };
            });
        }
    }
    function confirmRun(item) {
        setDialogMode("confirm");
        el("dialog-body").className = "";
        text("dialog-title", "Confirm: " + item.name);
        text("dialog-state", "This action changes the system.");
        text("dialog-description", item.manifest.confirmation); clear(el("dialog-meta"));
        text("action", "Continue"); text("back", "Cancel"); el("back").focus();
        el("back").onclick = function () {text("back","Back");openDetails(item);};
        el("action").onclick = function () {text("back","Back");el("back").onclick=closeDialog;perform(item,"run");};
    }
    function closeDialog() {
        show("overlay",false); setDialogMode(""); el("dialog-state").className=""; el("dialog-body").className="";
        var button = document.getElementById(returnFocusId); if (button) button.focus();
    }
    function showDisclaimer() {
        setDialogMode("disclaimer");
        el("dialog-body").className="";
        text("dialog-title","Before you begin"); el("dialog-dot").className="dot";
        el("dialog-state").className="startup-warning";
        text("dialog-state","Use only while parked.");
        text("dialog-description","Choose how you want to customize your Mazda.\nRead each description before installing.\n\nKeep the system on and leave the USB stick plugged in until everything is finished.");
        clear(el("dialog-meta")); text("dialog-output","");
        text("back","Exit"); text("action","OK");
        show("back",true); show("action",true); show("result-ok",false); show("overlay",true);
        el("dialog-body").scrollTop=0;
        el("back").disabled=false; el("action").disabled=false;
        el("back").onclick=exit;
        el("action").onclick=function () {
            if(accepted || closing)return;
            accepted=true; text("back","Back"); el("back").onclick=closeDialog;
            closeDialog(); discover();
        };
        controls(); footer("Read the notice, then select OK or Exit."); el("action").focus();
    }
    function showResult(title, message, critical, callback, status) {
        el("dialog-body").className = status ? "bottom-info" : "";
        setDialogMode("result"); show("overlay",true); text("dialog-title",title);
        el("dialog-dot").className = "dot " + (critical ? "error" : "uninstalled");
        el("dialog-state").className = status ? "operation-status" : "";
        text("dialog-state",status || "");
        text("dialog-description", critical ? "Further actions are blocked. Do NOT reboot. Check the USB reports." : ""); clear(el("dialog-meta")); text("dialog-output",message);
        show("back",false); show("action",false); show("result-ok",true); el("result-ok").disabled=false;
        el("dialog-body").scrollTop = 0;
        el("result-ok").onclick = function () {closeDialog();callback();}; el("result-ok").focus();
    }
    function executeAction(item, action, callback, restoreHash) {
        if(action==="restore-original") {call(["restore-original",item.id,restoreHash],callback);return;}
        if(action!=="run" || !item.manifest.progress) {call(["action",item.id,action],callback);return;}
        call(["start-run",item.id],function(error,result) {
            if(error || resultError(result)) {callback(error,result);return;}
            var job=trim(result.stdout), started=new Date().getTime();
            if(!/^job\.[A-Za-z0-9]+$/.test(job)) {callback("Invalid background job response.",result);return;}
            function poll() {
                call(["job-status",job],function(error,result) {
                    if(error || resultError(result)) {callback("Background job state is uncertain: "+(error||resultError(result)),result);return;}
                    var lines=result.stdout.split("\n");
                    if(lines[0]==="running") {
                        var done=Number(lines[1]),total=Number(lines[2]),message=lines[3]||"Working";
                        text("dialog-state",message+(total>0?" ("+done+"/"+total+")":"")+" - "+Math.floor((new Date().getTime()-started)/1000)+" s");
                        window.setTimeout(poll,1000);return;
                    }
                    if(lines[0]!=="done" || !/^[0-9]+$/.test(lines[1])) {callback("Invalid background job state.",result);return;}
                    var code=Number(lines[1]);
                    call(["job-output",job,"stdout"],function(error,out) {
                        if(error || resultError(out)) {callback("Could not read background result.",out);return;}
                        call(["job-output",job,"stderr"],function(error,err) {
                            if(error || resultError(err)) {callback("Could not read background error output.",err);return;}
                            callback(null,{started:true,startError:"",exitCode:code,signal:null,stdout:out.stdout,stderr:err.stdout,
                                stdoutTruncated:out.stdoutTruncated,stderrTruncated:err.stdoutTruncated});
                        });
                    });
                });
            }
            poll();
        });
    }
    function originalRestoreOffer(result) {
        if (!result || resultError(result) || result.stdoutTruncated || result.stderrTruncated) return null;
        var fields=result.stdout.split("\t");
        if (fields.length!==3 || fields[0]!=="available" || !/^[0-9a-f]{32}$/.test(fields[1]) || !/^\/[^\x00-\x1f\x7f]+\n$/.test(fields[2])) return null;
        return {hash:fields[1],path:fields[2].slice(0,-1)};
    }
    function confirmOriginalRestore(item, hash, path, cancel) {
        setDialogMode("restore-confirm"); el("dialog-body").className="";
        el("dialog-state").className="";
        text("dialog-title","Restore original file?"); el("dialog-dot").className="dot unavailable";
        text("dialog-state","A verified original backup is available");
        text("dialog-description","Restoring this file removes ALL tweaks affecting it.\nYour current file and original backup will be saved to USB first.\n\n"+path+"\n\nThis does not install the tweak. You can retry Install afterwards.");
        clear(el("dialog-meta")); text("dialog-output","");
        show("overlay",true); show("back",true); show("action",true); show("result-ok",false);
        text("back","Back"); text("action","Restore original");
        el("back").disabled=false; el("action").disabled=false;
        el("back").onclick=cancel;
        el("action").onclick=function () {perform(item,"restore-original",hash);};
        el("dialog-body").scrollTop=0; el("back").focus();
    }
    function perform(item, action, restoreHash) {
        var actionName = action==="restore-original" ? "Restore" : action.charAt(0).toUpperCase() + action.slice(1);
        operating = true; controls(); setDialogMode("working");
        el("dialog-body").className = "bottom-info";
        el("dialog-state").className = "operation-status";
        text("dialog-state",actionName + " in progress...");
        text("dialog-description","Keep the system on and do not remove the USB drive");
        clear(el("dialog-meta"));
        el("back").disabled = true; el("action").disabled = true;
        footer("Working: " + item.name);
        function complete(error,result) {
            operating=false;
            var recoveryCandidate=result && /(^|\n)MZD_RECOVERY_CANDIDATE\n/.test(result.stdout);
            if (result && result.stdout) result.stdout=result.stdout.replace(/^MZD_RECOVERY_CANDIDATE\n/gm,"");
            var problem = error || resultError(result);
            var critical = !!error || !result || (result.started && (result.exitCode === 2 || !!result.signal || result.exitCode === null));
            if (critical) locked=true;
            if (!problem && (action==="restore-original" || (item.manifest.reboot_required && (action === "install" || action === "uninstall" || action === "run")))) restartRequired=true;
            var message = result ? trim(result.stdout + (result.stderr ? "\n" + result.stderr : "")) : "";
            // Old saved workers may still return their original progress preamble.
            // Keep the single live status row authoritative; retain useful details.
            message = trim(message.replace(/^(?:install|uninstall|run) in progress\. Do not remove the USB drive\.[ \t]*$/gim, "")
                .replace(/^(?:install|uninstall|run) completed\.[ \t]*(?:Other changes were preserved\.)?[ \t]*$/gim, "Other changes were preserved."));
            if (!message) message = problem ? String(problem) : "No additional details.";
            if (result && (result.stdoutTruncated || result.stderrTruncated)) message += "\n\nOutput was truncated. See the tweak reports on USB.";
            item.state = "error"; item.error = problem ? String(problem) : "Status will be checked after OK."; updateCard(item);
            var status = actionName + (problem ? " failed" : " completed");
            controls(); footer(locked ? "Critical worker failure. Do NOT reboot." : status);
            var title = critical ? "Manual check required" : problem ? "Operation failed" : "Operation completed";
            showResult(title,message,critical,function () {
                if (locked) return;
                if (item.manifest.refresh_all) {refreshAll();return;}
                scanning=true; controls(); footer("Checking " + item.name + "...");
                checkStatus(item,function () {
                    scanning=false;controls();footer(locked ? "Critical worker failure. Do NOT reboot." : "Status updated - " + item.name);
                    if (recoveryCandidate && action==="install" && !locked) openDetails(item);
                });
            },status);
        }
        executeAction(item,action,complete,restoreHash);
    }
    function restorePrimary() {
        if (!manager) return "Native focus controller unavailable.";
        try {manager.SetRequiredSurfaces("JCI_OPERA_PRIMARY",0);manager.SetKeyboardFocus("JCI_OPERA_PRIMARY");return "";}
        catch (e) {return String(e);}
    }
    function leaveInstaller(restart) {
        if (operating || closing || (restart && (locked || scanning))) return;
        closing=true;controls();
        el("back").disabled=true;el("action").disabled=true;
        footer(restart ? "Preparing restart..." : "Returning to Mazda...");
        var problem = restart ? "User confirmed restart" : restorePrimary();
        call(["event",restart ? "restart" : "close",problem || "Primary visibility and focus requested"],function (error,result) {
            if(error || resultError(result)) {
                closing=false;controls();
                el("back").disabled=false;el("action").disabled=false;
                text("dialog-state","Could not close: "+(error || resultError(result)));
                footer("Exit failed; retry Exit.");
            }
        });
    }
    function exit() {
        if (operating || closing) return;
        if (!restartRequired || locked) {leaveInstaller(false);return;}
        setDialogMode("restart");returnFocusId="exit";
        el("dialog-body").className="";
        text("dialog-title","Restart recommended");el("dialog-dot").className="dot installed";
        text("dialog-state","Changes were made during this session.");
        text("dialog-description","Restart the CMU to activate all changes.\nSelect Restart now, or Exit to restart later.");
        clear(el("dialog-meta"));text("dialog-output","");
        text("back","Exit");text("action","Restart");
        show("back",true);show("action",true);show("result-ok",false);show("overlay",true);
        el("back").disabled=false;el("action").disabled=scanning || locked;el("dialog-body").scrollTop=0;
        el("back").onclick=function(){leaveInstaller(false);};
        el("action").onclick=function(){leaveInstaller(true);};
        el("back").focus();
    }
    el("back").onclick=closeDialog;
    el("refresh").onclick=function () {if (accepted && !scanning && !operating && !locked) refreshAll();};
    el("exit").onclick=exit;
    function controllerBack(event) {
        // Backspace is the CMU Back button. Always suppress browser history.
        if(event.preventDefault)event.preventDefault();event.returnValue=false;
        if(operating || closing)return;
        if(dialogMode==="restore-confirm")el("back").onclick();else if(dialogMode==="restart")leaveInstaller(false);else if(dialogMode==="confirm")openDetails(selected);else if(dialogMode==="details")closeDialog();else if(dialogMode==="disclaimer" || !dialogMode)exit();
    }
    document.onkeydown=function (event) {
        event=event||window.event; var key=event.keyCode||event.which, nodes, buttons=[],i,index=-1;
        if(key===8) {
            // Mazda emits goBack on keyup, not keydown or auto-repeat.
            if(event.preventDefault)event.preventDefault();event.returnValue=false;return;
        }
        // Original CMU Multicontroller.js: M = clockwise, N = counterclockwise.
        // Route rotation to focus navigation; up/down keep detail-text scrolling.
        if(key===77)key=39;else if(key===78)key=37;
        if (key===27) {
            if (dialogMode==="restore-confirm") el("back").onclick(); else if (dialogMode==="restart") leaveInstaller(false); else if (dialogMode==="confirm") openDetails(selected); else if (dialogMode==="details") closeDialog(); else if (dialogMode==="disclaimer" || !dialogMode) exit(); else return;
        } else if (key===38 || key===40 || key===37 || key===39) {
            // Up/down scroll detail text; left/right selects its action buttons.
            if (dialogMode && (key===38 || key===40)) el("dialog-body").scrollTop += key===38 ? -70 : 70;
            else {
                nodes=(dialogMode ? el("dialog-actions") : el("app")).getElementsByTagName("button");
                for(i=0;i<nodes.length;i++) if(!nodes[i].disabled && nodes[i].className.indexOf("hidden")===-1) buttons.push(nodes[i]);
                for(i=0;i<buttons.length;i++) if(buttons[i]===document.activeElement) index=i;
                if(buttons.length) {
                    index=(index+(key===37||key===38?-1:1)+buttons.length)%buttons.length;
                    buttons[index].focus();
                    if (!dialogMode && buttons[index].className==="tweak") {
                        var card=buttons[index],area=el("content");
                        if(card.offsetTop<area.scrollTop)area.scrollTop=card.offsetTop;
                        else if(card.offsetTop+card.offsetHeight>area.scrollTop+area.clientHeight)area.scrollTop=card.offsetTop+card.offsetHeight-area.clientHeight;
                    }
                }
            }
        } else if (key===13 || key===32) {
            var current=document.activeElement;
            if(current && !current.disabled && typeof current.onclick==="function") current.onclick(); else return;
        } else return;
        if(event.preventDefault)event.preventDefault();event.returnValue=false;
    };
    document.onkeyup=function (event) {
        event=event||window.event;
        if((event.keyCode||event.which)===8)controllerBack(event);
    };
    window.addEventListener("message",function (event) {
        if(event.source!==frame.contentWindow || event.origin!==config.origin)return;
        var data=event.data;if(!data || data.token!==config.token)return;
        if(data.type==="shell-result") {
            var callback=pending[data.id];if(!callback)return;delete pending[data.id];
            if(data.result) {data.result.stdout=outputText(data.result.stdout||"");data.result.stderr=outputText(data.result.stderr||"");}
            callback(data.error,data.result);return;
        }
        if(data.type!=="shell-ready" || connected)return;
        connected=true;
        var nativeMessage="";
        try {
            manager=new WaylandManager();manager.SetRequiredSurfaces("JCI_OPERA_SECONDARY",0);manager.SetKeyboardFocus("JCI_OPERA_SECONDARY");
        } catch(e) {nativeMessage=String(e);}
        // The parent shell performs the vehicle-confirmed direct D-Bus switch
        // after this event; successful JS calls alone did not make it visible.
        call(["event","ready","viewport="+window.innerWidth+"x"+window.innerHeight+"; native="+(nativeMessage||"requested")],function(error,result) {
            if(error || resultError(result)) {footer("Cannot initialize USB session");return;}
            showDisclaimer();
            updateMetrics();
            window.setInterval(updateMetrics, 5000);
        });
    },false);
    controls(); frame.src=config.origin+"/#"+config.token;
}());
