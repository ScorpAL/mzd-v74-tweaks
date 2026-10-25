/* Developer-only offline bridge. Never loaded by the USB installer. */
(function () {
    "use strict";
    var frame = document.getElementById("transport"), manifests = window.previewManifests;
    var states = {"list-beep":"installed", "list-loop":"unavailable", "shorter-delay":"broken"};
    var jobs = {}, nextJob = 0, sample = 0;
    function reply(data) {
        window.dispatchEvent(new MessageEvent("message", {
            source:frame.contentWindow, origin:"preview", data:data
        }));
    }
    function ok(stdout, code, stderr) {
        return {started:true, exitCode:code || 0, signal:null, stdout:stdout || "", stderr:stderr || "",
            stdoutTruncated:false, stderrTruncated:false};
    }
    function process(args) {
        var id = args[1], action = args[2], state, job, raw;
        if (args[0] === "event") {
            if (id === "restart") {
                document.body.innerHTML = '<p style="padding:35px">Preview: restart requested. No device is restarted. Reload to restart the preview.</p>';
            }
            if (id === "close") {
                document.body.innerHTML = '<p style="padding:35px">Preview closed. Reload to restart.</p>';
            }
            return ok();
        }
        if (args[0] === "metrics") {
            sample++;
            return ok("cpu\t" + (1000+sample*100) + "\t" + (700+sample*70) + "\t" +
                (args[1] === "0" ? "-" : "30") + "\ndisk\t/\t42\ndisk\t/jci\t18\ndisk\t/data\t65\ndisk\t/tmp/mnt/sdb1\t80\n");
        }
        if (args[0] === "list") return ok(Object.keys(manifests).join("\n")+"\n");
        if (args[0] === "manifest") return manifests[id] ? ok(manifests[id]) : ok("",1,"Missing preview manifest.");
        if (args[0] === "action") {
            if (action === "status") {
                state = states[id] || "uninstalled";
                return ok(state+"\n",0,state === "unavailable" ? "Preview: target file does not match this patch." :
                    state === "broken" ? "Preview: incomplete installation detected." : "");
            }
            states[id] = action === "install" ? "installed" : "uninstalled";
            return ok("PREVIEW ONLY: " + action + " completed. No files were changed.");
        }
        if (args[0] === "start-run") {
            raw = "job.preview" + (++nextJob); jobs[raw] = 0; return ok(raw+"\n");
        }
        if (args[0] === "job-status") {
            job = ++jobs[id];
            return ok(job < 4 ? "running\n"+job+"\n4\nSimulating export (preview only)\n" : "done\n0\n");
        }
        if (args[0] === "job-output") return ok(action === "stdout" ? "PREVIEW ONLY: Export completed. Nothing was written to USB." : "");
        return ok("",1,"Unsupported preview request.");
    }
    // Keep the real app unchanged. Replace only this preview iframe's transport.
    frame.contentWindow.postMessage = function (message) {
        if (message.type !== "shell-exec") return;
        window.setTimeout(function () {
            reply({type:"shell-result", token:"preview", id:message.id, result:process(message.args.slice(1))});
        },120);
    };
    Object.defineProperty(frame,"src",{set:function () {
        window.setTimeout(function () {reply({type:"shell-ready",token:"preview"});},0);
    }});
}());
