# ecoenergyApp.js (MZD Connect 74.00.324 EU): at ignition off show the Fuel Consumption ending screen
# instead of the i-stop one, and show it for 7 s instead of 5 s.
# Usage: python ecoenergyApp-patch.py <original ecoenergyApp.js> <output>
import sys, hashlib
src, dst = sys.argv[1], sys.argv[2]
ORIG = "32f3607cbbbb0532f28bb726882e990b"
d = open(src, "rb").read()
if hashlib.md5(d).hexdigest() != ORIG:
    sys.exit("ERROR: not the known original file (md5 %s expected)" % ORIG)
anchor = b"    baseApp.init(this, uiaId);\n"
assert d.count(anchor) == 1
mod = anchor + b"""
    // MOD (fuel-ending): show the Fuel Consumption ending screen on i-stop cars too.
    // On i-stop cars the MMUI always sends the EndingEffectiveness context;
    // redirect it to EndingFuelConsumption (what cars without i-stop get).
    var _modOrigHandleContext = this.handleContext;
    this.handleContext = function(contextObj)
    {
        if (contextObj && contextObj.ctxtId === "EndingEffectiveness")
        {
            log.info("MOD fuel-ending: EndingEffectiveness -> EndingFuelConsumption");
            contextObj.ctxtId = "EndingFuelConsumption";
            if (contextObj.params && contextObj.params.payload && !contextObj.params.payload.fuelEconomyBarGraphUnit && this._globalUnit)
            {
                contextObj.params.payload.fuelEconomyBarGraphUnit = this._globalUnit;
            }
        }
        _modOrigHandleContext(contextObj);
    }.bind(this);
"""
out = d.replace(anchor, mod)
# MOD: ending screen shown for 7 s instead of 5 s
t_old = b"    this.endingTimer = setTimeout(this._stopEndingTimer.bind(this), 5000);"
assert out.count(t_old) == 1
out = out.replace(t_old, b"    this.endingTimer = setTimeout(this._stopEndingTimer.bind(this), 7000); // MOD: 5000 -> 7000")
open(dst, "wb").write(out)
print("OK", hashlib.md5(out).hexdigest())
