let myModulePath = "/dummy"; // For mock execution

if (typeof window.mod !== "undefined") {
    // For WebUI X / MMRL
    myModulePath = window.mod.path.moduleDir;
} else if (typeof window.ksu !== "undefined" && typeof window.ksu.moduleInfo === "function") {
    // For KernelSU original
    try {
        const info = JSON.parse(window.ksu.moduleInfo());
        myModulePath = info.moduleDir;
    } catch (err) { // fallback
        console.log(`cannot get the module path automatically: ${err}`);
        myModulePath = "/data/adb/modules/bt-clipping-preventer";
    };
}

function MyExec(cmd, options) {
    if (typeof window.ksu === 'undefined') {
        // --- Mock KernelSU Environment for Browser Testing ---
        // (This fallback automatically deletes its dummy presence once deployed in the actual KSU environment)
        console.log(`[Mock KSU] Executing: ${cmd}`);
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                if (Math.random() > 0.3) {
                    if (cmd.match(/ --max$/)) { // In case of command "getVolumeCurve.sh --max" 
                        const x = (Math.floor(Math.random() * 1201.0) - 1200.0) / 100.0;
                        resolve({ errno: 0, stdout: x.toFixed(2), stderr: "" });
                    } else {
                        resolve({ errno: 0, stdout: "Updated to the current audio configuration on the fly.", stderr: "" });
                    };
                } else {
                    resolve({ errno: 1, stdout: "", stderr: "sh: error: Audioserver denied a request." });
                };
            }, 1200);
        });
    } else {
        return new Promise((resolve, reject) => {
            const callbackName = `exec_cb_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
            window[callbackName] = (errno, stdout, stderr) => {
                delete window[callbackName];
                resolve({ errno, stdout, stderr });
            };
            window.ksu.exec(cmd, JSON.stringify(options), callbackName);
        });
    };
}
// ------------------------------------------------------

// DOM Elements
const limitSlider = document.getElementById('limitSlider');
const targetValueDisplay = document.getElementById('targetValueDisplay');
const applyButton = document.getElementById('applyButton');
const currentLimitText = document.getElementById('currentLimitText');
const statusIndicator = document.getElementById('statusIndicator');
const resultBadge = document.getElementById('resultBadge');
const resultConsole = document.getElementById('resultConsole');

// Internal State
let currentLimit = -6.0;
let selectedLimit = -6.0;

// Track initialization to fetch current settings on boot
window.addEventListener('DOMContentLoaded', async () => {
    // Optional: Implement initialization if you want to read existing config via 'cat /path/to/file'
    const shellCommand = `/system/bin/sh ${myModulePath}/webroot/getVolumeCurve.sh --max`;
    try {
        // Call KernelSU WebUI Native Bridge
        // ksu.exec natively handles async shell pipes and returns { errno, stdout, stderr }
        const result = await MyExec(shellCommand, {});
        const timestamp = new Date().toLocaleTimeString();
        // Handle Execution Outputs based on Linux Exit Codes (errno == 0 means Success)
        if (result.errno === 0) {
            // Success Phase
            currentLimit = parseFloat(`${result.stdout}`)
            selectedLimit = currentLimit;
            currentLimitText.textContent = currentLimit;
            targetValueDisplay.textContent = selectedLimit;
            resultBadge.textContent = `Getting the volume limit from the audio system: SUCCESS [time: ${timestamp}]`;
            resultBadge.className = 'result-badge success';
            resultConsole.textContent = `Getting the active volume curve data: Exit Code: ${result.errno}\n\n[STDOUT]\n${result.stdout || '(No text output)'}`;
        } else {
            // Shell Command Error Phase (e.g., Syntax error, bad permissions, invalid path)
            resultBadge.textContent = `Getting the volume limit: ERROR [time: ${timestamp}]`;
            resultBadge.className = 'result-badge error';
            resultConsole.textContent = `Getting the active volume curve data: Exit Code: ${result.errno}\n\n[STDERR]\n${result.stderr}`;
        }
    } catch (jsError) {
        // 5. JavaScript/Environment Exception Handler
        resultBadge.textContent = 'Getting the volume limit: EXCEPTION';
        resultBadge.className = 'result-badge error';
        resultConsole.textContent = `Getting the active volume curve data: Critical UI Error: ${jsError.message}`;
    }
});

// Handle Slider Input
limitSlider.addEventListener('input', (event) => {
    selectedLimit = parseFloat(event.target.value);
    targetValueDisplay.textContent = selectedLimit;
    
    if (selectedLimit !== currentLimit) {
        applyButton.disabled = false;
    } else {
        applyButton.disabled = true;
    }
});

// Handle Action Button Click using Native KernelSU Shell Bridge
applyButton.addEventListener('click', async () => {
    // 1. Enter Loading / Busy State
    applyButton.disabled = true;
    applyButton.textContent = 'Execute a command...';
    statusIndicator.classList.add('updating');
    limitSlider.disabled = true;

    resultBadge.className = 'result-badge';
    resultBadge.textContent = '';
    resultConsole.innerHTML = 'Changing the current audio configuration...';
    // 2. Build the actual Root Shell Command
    const shellCommand = `/system/bin/sh ${myModulePath}/webroot/applySetting.sh ${selectedLimit}`;
    try {
        // 3. Call KernelSU WebUI Native Bridge
        // ksu.exec natively handles async shell pipes and returns { errno, stdout, stderr }
        const result = await MyExec(shellCommand,  {});
        const timestamp = new Date().toLocaleTimeString();
        // 4. Handle Execution Outputs based on Linux Exit Codes (errno == 0 means Success)
        if (result.errno === 0) {
            // Success Phase
            currentLimit = selectedLimit;
            currentLimitText.textContent = `${currentLimit}`;
            resultBadge.textContent = `SUCCESS [time: ${timestamp}]`;
            resultBadge.className = 'result-badge success';
            resultConsole.textContent = `Exit Code: ${result.errno}\n\n[STDOUT]\n${result.stdout || '(No text output)'}`;
        } else {
            // Shell Command Error Phase (e.g., Syntax error, bad permissions, invalid path)
            resultBadge.textContent = `ERROR [time: ${timestamp}]`;
            resultBadge.className = 'result-badge error';
            resultConsole.textContent = `Exit Code: ${result.errno}\n\n[STDERR]\n${result.stderr}`;
            // Rollback user input components to original value
            selectedLimit = currentLimit;
            limitSlider.value = currentLimit;
            targetValueDisplay.textContent = currentLimit;
        }
    } catch (jsError) {
        // 5. JavaScript/Environment Exception Handler
        resultBadge.textContent = 'EXCEPTION';
        resultBadge.className = 'result-badge error';
        resultConsole.textContent = `Critical UI Error: ${jsError.message}`;
    } finally {
        // 6. Restore Control Blocks
        statusIndicator.classList.remove('updating');
        limitSlider.disabled = false;
        applyButton.textContent = 'Apply Changes';
        applyButton.disabled = true;
    }
});
