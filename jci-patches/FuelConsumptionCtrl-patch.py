# FuelConsumptionCtrl.js (MZD Connect 74.00.324 EU): show the L/100km value above every bar of both
# Fuel Consumption graphs (this drive 10-min + 1-min bars, and the 5 history bars).
# Usage: python FuelConsumptionCtrl-patch.py <original FuelConsumptionCtrl.js> <output>
import sys, hashlib
src, dst = sys.argv[1], sys.argv[2]
d = open(src, "rb").read()
ORIG = "9b0443778acc8ab1ac89ea6561f1b153"
if hashlib.md5(d).hexdigest() != ORIG:
    sys.exit("ERROR: not the known original file (md5 %s expected)" % ORIG)
print("original md5:", hashlib.md5(d).hexdigest())

helper = b'''
// MOD (bar-values): show the value above every bar of the fuel graphs.
// The graph areas are 109 px high and clip anything above, so on tall bars the value goes inside the bar.
FuelConsumptionCtrl.prototype._modSetBarLabel = function(bar, value, heightPx, widthPx, fontPx)
{
    if (!bar) { return; }
    var lbl = bar._modLbl;
    if (!lbl)
    {
        lbl = document.createElement('div');
        lbl.style.cssText = 'position:absolute;left:0px;width:' + widthPx + 'px;text-align:center;color:#fff;' +
                            'font-size:' + fontPx + 'px;line-height:' + (fontPx + 2) + 'px;white-space:nowrap;' +
                            'font-family:Tipperary, Arial, Helvetica, sans-serif;';
        bar.appendChild(lbl);
        bar._modLbl = lbl;
    }
    var v = parseFloat(value);
    if (!(v > 0))
    {
        lbl.innerHTML = '';
        return;
    }
    var txt = v.toFixed(1);
    lbl.innerHTML = txt;
    // On narrow bars a 4-character value (e.g. 12.8) gets a smaller, tighter font so it fits.
    var fs = fontPx, ls = '0px';
    if (widthPx < 30 && txt.length > 3) { fs = fontPx - 2; ls = '-1px'; }
    lbl.style.fontSize = fs + 'px';
    lbl.style.letterSpacing = ls;
    var above = fontPx + 6;
    lbl.style.top = (heightPx > (109 - above)) ? '4px' : ('-' + above + 'px');
};
FuelConsumptionCtrl.prototype._modSetCFERBarLabel = function(bar, value, heightPx)
{
    this._modSetBarLabel(bar, value, heightPx, 50, 22);
};

/*
 * Utility function to set the height of single CFER graph bar (e.g. the just-inserted one)
 */'''
anchor = b'''
/*
 * Utility function to set the height of single CFER graph bar (e.g. the just-inserted one)
 */'''
assert d.count(anchor) == 1
out = d.replace(anchor, helper)

# 1) history graph, single bar
a1 = b'''        bar.style.height = this._scaleDataToGraphY(this._CSSConstants["CFERGraphVisibleHeight"],
                                                   this._CFERGraphBarValues[barIdx],
                                                   this.properties.cumulativeFuelConfig.yAxisLimitValue,
                                                   false) + 'px';
          
    }'''
assert out.count(a1) == 1
out = out.replace(a1, a1[:-6] + b'''        this._modSetCFERBarLabel(bar, this._CFERGraphBarValues[barIdx], parseFloat(bar.style.height)); // MOD
    }''')

# 2) history graph, all bars
a2 = b'''            bar.style.height = this._scaleDataToGraphY(graphHeight,
                                                       this._CFERGraphBarValues[i],
                                                       yLimit,
                                                       false) + 'px';
'''
assert out.count(a2) == 1, out.count(a2)
out = out.replace(a2, a2 + b'''            this._modSetCFERBarLabel(bar, this._CFERGraphBarValues[i], parseFloat(bar.style.height)); // MOD
''')

# 3) this-drive graph, narrow (1-min) bars
b1 = b"""        bar.style.height = this._scaleDataToGraphY(this._CSSConstants["CDFEGraphVisibleHeight"],
                                                   this._CDFEGraphBarValues[barIdx],
                                                   this.properties.currentFuelConfig.yAxisLimitValue,
                                                   false) + 'px';
"""
assert out.count(b1) == 1
out = out.replace(b1, b1 + b"""        this._modSetBarLabel(bar, this._CDFEGraphBarValues[barIdx], parseFloat(bar.style.height), 21, 13); // MOD
""")
b2 = b"""            bar.style.height = this._scaleDataToGraphY(graphHeight,
                                                       this._CDFEGraphBarValues[i],
                                                       yLimit,
                                                       false) + 'px';
"""
assert out.count(b2) == 1
out = out.replace(b2, b2 + b"""            this._modSetBarLabel(bar, this._CDFEGraphBarValues[i], parseFloat(bar.style.height), 21, 13); // MOD
""")
# 4) this-drive graph, wide (10-min) bars
b3 = b"""        bar.style.height = this._scaleDataToGraphY(this._CSSConstants["CDFEGraphVisibleHeightRight"],
                                                   this._CDFEGraphBarValuesRight[barIdx],
                                                   this.properties.currentFuelConfig.yAxisLimitValue,
                                                   false) + 'px';
"""
assert out.count(b3) == 1
out = out.replace(b3, b3 + b"""        this._modSetBarLabel(bar, this._CDFEGraphBarValuesRight[barIdx], parseFloat(bar.style.height), 44, 18); // MOD
""")
b4 = b"""            bar.style.height = this._scaleDataToGraphY(graphHeight,
                                                       this._CDFEGraphBarValuesRight[i],
                                                       yLimit,
                                                       false) + 'px';
"""
assert out.count(b4) == 1
out = out.replace(b4, b4 + b"""            this._modSetBarLabel(bar, this._CDFEGraphBarValuesRight[i], parseFloat(bar.style.height), 44, 18); // MOD
""")
open(dst, "wb").write(out)
print("OK", hashlib.md5(out).hexdigest())
