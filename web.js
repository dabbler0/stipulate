(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['./brent-rjs', './text!./units.json', './text!./atoms.json'], function(brent, data, atomicData) {
    var AddExpression, BinaryOperation, CallExpression, DivExpression, ExecutionContext, ExpExpression, Expression, MulExpression, NegExpression, NumExpression, ParenExpression, StringExpression, SubExpression, UNITLESS, UnitNum, VarExpression, applyObj, checkObj, compositeObj, exports, functionScope, fundamental, fundamentals, getSigFigs, molarMassOfArray, objEquals, parseMap, parseUnit, renderChemicalArray, renderVar, units, _i, _len;
    exports = {};
    data = JSON.parse(data);
    atomicData = JSON.parse(atomicData);
    units = data.units;
    fundamentals = data.fundamentals;
    UNITLESS = {};
    for (_i = 0, _len = fundamentals.length; _i < _len; _i++) {
      fundamental = fundamentals[_i];
      UNITLESS[fundamental] = 0;
    }
    objEquals = function(a, b) {
      var key, val;
      for (key in a) {
        val = a[key];
        if (b[key] !== val) {
          return false;
        }
      }
      for (key in b) {
        val = b[key];
        if (a[key] !== val) {
          return false;
        }
      }
      return true;
    };
    checkObj = function(a, f) {
      var key, val;
      for (key in a) {
        val = a[key];
        if (!f(val)) {
          return false;
        }
      }
      return true;
    };
    applyObj = function(a, f) {
      var key, result;
      result = {};
      for (key in a) {
        result[key] = f(a[key]);
      }
      return result;
    };
    compositeObj = function(a, b, f) {
      var key, result;
      result = {};
      for (key in a) {
        result[key] = f(a[key], b[key]);
      }
      return result;
    };
    parseUnit = function(parsed) {
      var bottom, referredFundamental, result, resultNum, top, unit, val, _j, _k, _l, _len1, _len2, _len3, _ref, _ref1;
      top = parsed[0];
      bottom = parsed[1];
      result = {};
      resultNum = 1;
      for (_j = 0, _len1 = fundamentals.length; _j < _len1; _j++) {
        fundamental = fundamentals[_j];
        result[fundamental] = 0;
      }
      if (top != null) {
        for (_k = 0, _len2 = top.length; _k < _len2; _k++) {
          unit = top[_k];
          _ref = units[unit[0]].units;
          for (referredFundamental in _ref) {
            val = _ref[referredFundamental];
            result[referredFundamental] += val * unit[1];
          }
          resultNum *= Math.pow(units[unit[0]].number, unit[1]);
        }
      }
      if (bottom != null) {
        for (_l = 0, _len3 = bottom.length; _l < _len3; _l++) {
          unit = bottom[_l];
          _ref1 = units[unit[0]].units;
          for (referredFundamental in _ref1) {
            val = _ref1[referredFundamental];
            result[referredFundamental] -= val * unit[1];
          }
          resultNum /= Math.pow(units[unit[0]].number, unit[1]);
        }
      }
      return {
        number: resultNum,
        units: result
      };
    };
    exports.UnitNum = UnitNum = (function() {
      function UnitNum(num, unit, sigFigs) {
        this.num = num;
        this.unit = unit;
        this.sigFigs = sigFigs != null ? sigFigs : Infinity;
      }

      UnitNum.prototype.add = function(other) {
        var lastDigit, otherLastDigit, resultFirstDigit;
        if (!objEquals(this.unit, other.unit)) {
          throw new Error('Cannot add two numbers of different units');
        }
        lastDigit = Math.floor(Math.log(this.num) / Math.log(10)) - this.sigFigs;
        otherLastDigit = Math.floor(Math.log(other.num) / Math.log(10)) - other.sigFigs;
        resultFirstDigit = Math.floor(Math.log(this.num + other.num) / Math.log(10));
        return new UnitNum(this.num + other.num, this.unit, resultFirstDigit - Math.max(lastDigit, otherLastDigit));
      };

      UnitNum.prototype.sub = function(other) {
        var lastDigit, otherLastDigit, resultFirstDigit;
        if (!objEquals(this.unit, other.unit)) {
          throw new Error('Cannot subtract two numbers of different units');
        }
        lastDigit = Math.floor(Math.log(this.num) / Math.log(10)) - this.sigFigs;
        otherLastDigit = Math.floor(Math.log(other.num) / Math.log(10)) - other.sigFigs;
        resultFirstDigit = Math.floor(Math.log(this.num - other.num) / Math.log(10));
        return new UnitNum(this.num - other.num, this.unit, resultFirstDigit - Math.max(lastDigit, otherLastDigit));
      };

      UnitNum.prototype.mul = function(other) {
        return new UnitNum(this.num * other.num, compositeObj(this.unit, other.unit, function(a, b) {
          return a + b;
        }), Math.min(other.sigFigs, this.sigFigs));
      };

      UnitNum.prototype.div = function(other) {
        return new UnitNum(this.num / other.num, compositeObj(this.unit, other.unit, function(a, b) {
          return a - b;
        }), Math.min(other.sigFigs, this.sigFigs));
      };

      UnitNum.prototype.exp = function(other) {
        return new UnitNum(Math.pow(this.num, other.num), applyObj(this.unit, function(x) {
          return x * other.num;
        }), this.sigFigs);
      };

      UnitNum.prototype.terms = function(desiredUnits) {
        var displayNum, element, i, result, row, system, unit, vals, _j, _k, _len1, _len2;
        system = [];
        vals = [];
        for (fundamental in this.unit) {
          row = [];
          for (_j = 0, _len1 = desiredUnits.length; _j < _len1; _j++) {
            unit = desiredUnits[_j];
            row.push(unit.units[fundamental]);
          }
          vals.push(this.unit[fundamental]);
          system.push(row);
        }
        result = numeric.solve(system, vals);
        displayNum = this.num;
        for (i = _k = 0, _len2 = result.length; _k < _len2; i = ++_k) {
          element = result[i];
          displayNum /= Math.pow(desiredUnits[i].number, element);
        }
        return {
          displayNum: displayNum,
          result: result
        };
      };

      UnitNum.prototype.express = function(desiredUnits) {
        var bottom, displayNum, displayString, element, i, result, top, _j, _len1, _ref;
        _ref = this.terms(desiredUnits), displayNum = _ref.displayNum, result = _ref.result;
        top = [];
        bottom = [];
        for (i = _j = 0, _len1 = result.length; _j < _len1; i = ++_j) {
          element = result[i];
          if (element > 0) {
            if (element === 1) {
              top.push(desiredUnits[i].name);
            } else {
              top.push("" + desiredUnits[i].name + "^{" + element + "}");
            }
          } else if (element < 0) {
            if (element === -1) {
              bottom.push(desiredUnits[i].name);
            } else {
              bottom.push("" + desiredUnits[i].name + "^{" + (-element) + "}");
            }
          }
        }
        displayString = displayNum.toPrecision(Math.min(21, this.sigFigs));
        displayString = displayString.replace(/e\+?(\-?\d+)/, ' \\cdot 10^{$1}');
        if (bottom.length > 0) {
          if (top.length > 0) {
            return "" + displayString + " \\frac{" + (top.join(' ')) + "}{" + (bottom.join(' ')) + "}";
          } else {
            return "\\frac{" + displayString + "}{" + (bottom.join(' ')) + "}";
          }
        } else if (top.length > 0) {
          return "" + displayString + " " + (top.join(' '));
        } else {
          return displayString;
        }
      };

      return UnitNum;

    })();
    getSigFigs = function(string) {
      var first, last, result, _ref;
      string = string.slice(0, +string.indexOf('e') + 1 || 9e9);
      _ref = string.split('.'), first = _ref[0], last = _ref[1];
      if (last != null) {
        return first.length + last.length;
      } else {
        result = /[1-9]0*$/.exec(string);
        if ((result != null) && result.index >= 0) {
          return result.index + 1;
        } else {
          return first.length;
        }
      }
    };
    UnitNum.fromArray = function(array) {
      var num, unit;
      if (array[0] !== 'UNIT') {
        throw new Error('Array is not of desired UNIT type.');
      }
      num = Number(array[1]);
      unit = parseUnit(array[2]);
      num *= unit.number;
      unit.number = 1;
      return new UnitNum(num, unit.units, getSigFigs(array[1]));
    };
    Expression = (function() {
      function Expression() {}

      return Expression;

    })();
    BinaryOperation = (function(_super) {
      __extends(BinaryOperation, _super);

      function BinaryOperation(array) {
        this.left = Expression.fromArray(array[1]);
        this.right = Expression.fromArray(array[2]);
      }

      BinaryOperation.prototype.render = function(usingUnits) {
        return "" + (this.left.render(usingUnits)) + " " + this.op + " " + (this.right.render(usingUnits));
      };

      BinaryOperation.prototype.renderSubbed = function(scope, usingUnits) {
        return "" + (this.left.renderSubbed(scope, usingUnits)) + " " + this.op + " " + (this.right.renderSubbed(scope, usingUnits));
      };

      return BinaryOperation;

    })(Expression);
    AddExpression = (function(_super) {
      __extends(AddExpression, _super);

      function AddExpression() {
        this.op = '+';
        AddExpression.__super__.constructor.apply(this, arguments);
      }

      AddExpression.prototype.compute = function(scope, usingUnits) {
        return this.left.compute(scope, usingUnits).add(this.right.compute(scope, usingUnits));
      };

      return AddExpression;

    })(BinaryOperation);
    SubExpression = (function(_super) {
      __extends(SubExpression, _super);

      function SubExpression() {
        this.op = '-';
        SubExpression.__super__.constructor.apply(this, arguments);
      }

      SubExpression.prototype.compute = function(scope, usingUnits) {
        return this.left.compute(scope, usingUnits).sub(this.right.compute(scope, usingUnits));
      };

      return SubExpression;

    })(BinaryOperation);
    MulExpression = (function(_super) {
      __extends(MulExpression, _super);

      function MulExpression() {
        this.op = '\\cdot';
        MulExpression.__super__.constructor.apply(this, arguments);
      }

      MulExpression.prototype.compute = function(scope, usingUnits) {
        return this.left.compute(scope, usingUnits).mul(this.right.compute(scope, usingUnits));
      };

      return MulExpression;

    })(BinaryOperation);
    DivExpression = (function(_super) {
      __extends(DivExpression, _super);

      function DivExpression() {
        DivExpression.__super__.constructor.apply(this, arguments);
      }

      DivExpression.prototype.compute = function(scope, usingUnits) {
        return this.left.compute(scope, usingUnits).div(this.right.compute(scope, usingUnits));
      };

      DivExpression.prototype.render = function(usingUnits) {
        return "\\frac{" + (this.left.render(usingUnits)) + "}{" + (this.right.render(usingUnits)) + "}";
      };

      DivExpression.prototype.renderSubbed = function(scope, usingUnits) {
        return "\\frac{" + (this.left.renderSubbed(scope, usingUnits)) + "}{" + (this.right.renderSubbed(scope, usingUnits)) + "}";
      };

      return DivExpression;

    })(BinaryOperation);
    ExpExpression = (function(_super) {
      __extends(ExpExpression, _super);

      function ExpExpression() {
        ExpExpression.__super__.constructor.apply(this, arguments);
      }

      ExpExpression.prototype.compute = function(scope, usingUnits) {
        return this.left.compute(scope, usingUnits).exp(this.right.compute(scope, usingUnits));
      };

      ExpExpression.prototype.render = function(usingUnits) {
        return "" + (this.left.render(usingUnits)) + "^{" + (this.right.render(usingUnits)) + "}";
      };

      ExpExpression.prototype.renderSubbed = function(scope, usingUnits) {
        return "" + (this.left.renderSubbed(scope, usingUnits)) + "^{" + (this.right.renderSubbed(scope, usingUnits)) + "}";
      };

      return ExpExpression;

    })(BinaryOperation);
    NumExpression = (function(_super) {
      __extends(NumExpression, _super);

      function NumExpression(array) {
        this.val = UnitNum.fromArray(array);
      }

      NumExpression.prototype.compute = function() {
        return this.val;
      };

      NumExpression.prototype.render = function(usingUnits) {
        return this.val.express(usingUnits);
      };

      NumExpression.prototype.renderSubbed = function(scope, usingUnits) {
        return this.render(usingUnits);
      };

      return NumExpression;

    })(Expression);
    renderVar = function(name) {
      return name.replace(/\\d/g, '\\Delta ');
    };
    VarExpression = (function(_super) {
      __extends(VarExpression, _super);

      function VarExpression(array) {
        this.name = array[1];
      }

      VarExpression.prototype.compute = function(scope, usingUnits) {
        if (this.name in scope) {
          return scope[this.name];
        } else if (this.name in units) {
          return new UnitNum(1, units[this.name].units);
        } else {
          throw new Error("Cannot find variable " + this.name);
        }
      };

      VarExpression.prototype.render = function(usingUnits) {
        return renderVar(this.name);
      };

      VarExpression.prototype.renderSubbed = function(scope, usingUnits) {
        if (this.name in scope) {
          return scope[this.name].express(usingUnits);
        } else if (this.name in units) {
          return this.name;
        } else {
          throw new Error("Cannot find variable " + this.name);
        }
      };

      return VarExpression;

    })(Expression);
    CallExpression = (function(_super) {
      __extends(CallExpression, _super);

      function CallExpression(array) {
        this.fname = array[1];
        this.argument = Expression.fromArray(array[2]);
      }

      CallExpression.prototype.compute = function(scope, usingUnits) {
        return functionScope[this.fname](scope, usingUnits, this.argument.compute(scope, usingUnits));
      };

      CallExpression.prototype.render = function(usingUnits) {
        return "" + this.fname + "(" + (this.argument.render(usingUnits)) + ")";
      };

      CallExpression.prototype.renderSubbed = function(scope, usingUnits) {
        return functionScope[this.fname](scope, usingUnits, this.argument.compute(scope, usingUnits)).express(usingUnits);
      };

      return CallExpression;

    })(Expression);
    ParenExpression = (function(_super) {
      __extends(ParenExpression, _super);

      function ParenExpression(array) {
        this.value = Expression.fromArray(array[1]);
      }

      ParenExpression.prototype.compute = function(scope, usingUnits) {
        return this.value.compute(scope, usingUnits);
      };

      ParenExpression.prototype.render = function(usingUnits) {
        return "(" + (this.value.render(usingUnits)) + ")";
      };

      ParenExpression.prototype.renderSubbed = function(scope, usingUnits) {
        return "(" + (this.value.renderSubbed(scope, usingUnits)) + ")";
      };

      return ParenExpression;

    })(Expression);
    NegExpression = (function(_super) {
      __extends(NegExpression, _super);

      function NegExpression(array) {
        this.value = Expression.fromArray(array[1]);
      }

      NegExpression.prototype.compute = function(scope, usingUnits) {
        return this.value.compute(scope, usingUnits).mul(new UnitNum(-1, UNITLESS));
      };

      NegExpression.prototype.render = function(usingUnits) {
        return "-" + (this.value.render(usingUnits));
      };

      NegExpression.prototype.renderSubbed = function(scope, usingUnits) {
        return "-" + (this.value.renderSubbed(scope, usingUnits));
      };

      return NegExpression;

    })(Expression);
    renderChemicalArray = function(arr) {
      var element, res, _j, _len1;
      res = [];
      for (_j = 0, _len1 = arr.length; _j < _len1; _j++) {
        element = arr[_j];
        if (element[0] in atomicData) {
          if (element[1] === 1) {
            res.push(element[0]);
          } else {
            res.push("" + element[0] + "_{" + element[1] + "}");
          }
        } else {
          res.push("(" + (renderChemicalArray(element[0])) + ")_{" + element[1] + "}");
        }
      }
      return res.join(' ');
    };
    StringExpression = (function(_super) {
      __extends(StringExpression, _super);

      function StringExpression(array) {
        this.str = array[1].slice(1, -1);
      }

      StringExpression.prototype.compute = function(scope, usingUnits) {
        return this.str;
      };

      StringExpression.prototype.render = function() {
        try {
          return renderChemicalArray(chemical.parse(this.str).chem);
        } catch (_error) {
          return this.str;
        }
      };

      StringExpression.prototype.renderSubbed = function() {
        return this.render();
      };

      return StringExpression;

    })(Expression);
    molarMassOfArray = function(array) {
      var element, mass, _j, _len1;
      mass = 0;
      for (_j = 0, _len1 = array.length; _j < _len1; _j++) {
        element = array[_j];
        if (element[0] in atomicData) {
          mass += atomicData[element[0]] * element[1];
        } else {
          mass += molarMassOfArray(element[0]) * element[1];
        }
      }
      return mass;
    };
    functionScope = {
      'ln': function(scope, desiredUnits, n) {
        return new UnitNum(Math.log(n.terms(desiredUnits).displayNum), UNITLESS, n.sigFigs);
      },
      'log': function(scope, desiredUnits, n) {
        return new UnitNum(Math.log(n.terms(desiredUnits).displayNum) / Math.log(10), UNITLESS, n.sigFigs);
      },
      'mm': function(scop, desiredUnits, n) {
        return new UnitNum(molarMassOfArray(chemical.parse(n).chem) / 1000, {
          'kg': 1,
          'm': 0,
          's': 0,
          'mol': -1,
          'A': 0,
          'K': 0
        }, 4);
      }
    };
    parseMap = {
      '+': AddExpression,
      '-': SubExpression,
      '/': DivExpression,
      '*': MulExpression,
      '^': ExpExpression,
      'UMINUS': NegExpression,
      'STRING': StringExpression,
      'UNIT': NumExpression,
      'VARIABLE': VarExpression,
      'CALL': CallExpression,
      'PARENS': ParenExpression
    };
    Expression.fromArray = function(array) {
      return new parseMap[array[0]](array);
    };
    exports.ExecutionContext = ExecutionContext = (function() {
      function ExecutionContext(usingUnits, scope) {
        var key;
        if (usingUnits == null) {
          usingUnits = ['kg', 'm', 's', 'mol', 'A', 'K'];
        }
        this.scope = scope != null ? scope : {};
        this.usingUnits = (function() {
          var _j, _len1, _results;
          _results = [];
          for (_j = 0, _len1 = usingUnits.length; _j < _len1; _j++) {
            key = usingUnits[_j];
            _results.push(units[key]);
          }
          return _results;
        })();
      }

      ExecutionContext.prototype.setUnits = function(units) {
        var key;
        return this.usingUnits = (function() {
          var _j, _len1, _results;
          _results = [];
          for (_j = 0, _len1 = usingUnits.length; _j < _len1; _j++) {
            key = usingUnits[_j];
            _results.push(units[key]);
          }
          return _results;
        })();
      };

      ExecutionContext.prototype.execute = function(line) {
        var last_, left, parsed, parsedUnit, right, rstr, testNumber, unit, unitMultiplier, unitNultiplier;
        parsed = grammar.parse(line);
        rstr = '';
        if (parsed[0] === 'ASSIGN') {
          testNumber = Expression.fromArray(parsed[2]);
          last_ = '';
          rstr += renderVar(parsed[1]);
          if (last_ !== (last_ = testNumber.render(this.usingUnits))) {
            rstr += '=' + last_;
          }
          if (last_ !== (last_ = testNumber.renderSubbed(this.scope, this.usingUnits))) {
            rstr += '=' + last_;
          }
          this.scope[parsed[1]] = testNumber.compute(this.scope, this.usingUnits);
          if (last_ !== (last_ = this.scope[parsed[1]].express(this.usingUnits))) {
            rstr += '=' + last_;
          }
        } else if (parsed[0] === 'SOLVE') {
          left = Expression.fromArray(parsed[4]);
          right = Expression.fromArray(parsed[5]);
          if (parsed[6] != null) {
            parsedUnit = parseUnit(parsed[6]);
            unitMultiplier = parsedUnit.number;
            unit = parsedUnit.units;
          } else {
            unitNultiplier = 1;
            unit = UNITLESS;
          }
          brent.brent(((function(_this) {
            return function(x) {
              _this.scope[parsed[1]] = new UnitNum(x * unitMultiplier, unit, 4);
              return left.compute(_this.scope).num - right.compute(_this.scope, _this.usingUnits).num;
            };
          })(this)), Number(parsed[2]), Number(parsed[3]));
          rstr += "" + (left.render(this.usingUnits)) + " = " + (right.render(this.usingUnits)) + "; ";
          rstr += "" + (renderVar(parsed[1])) + " = " + (this.scope[parsed[1]].express(this.usingUnits));
        } else {
          testNumber = Expression.fromArray(parsed);
          rstr += testNumber.render(this.usingUnits);
          rstr += '=' + testNumber.renderSubbed(this.scope, this.usingUnits);
          rstr += '=' + testNumber.compute(this.scope, this.usingUnits).express(this.usingUnits);
        }
        return rstr;
      };

      return ExecutionContext;

    })();
    return exports;
  });

}).call(this);

//# sourceMappingURL=web.js.map
