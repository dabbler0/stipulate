
/*
 * OOP
 */

(function() {
  var Add, BinOp, Call, Chem, Div, Exp, Lok, Mul, Neg, Node, Num, Paren, Sub, Var, atomMasses, intersectZero, maxLen, mm_arr, nativeFunctions, noplus, renderNum, renderVar, solveSecantMethod,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Node = (function() {
    function Node() {
      this.children = [];
    }

    Node.prototype.subsitute = function(scope) {
      var child, _i, _len, _ref, _results;
      _ref = this.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(child.subsitute(scope));
      }
      return _results;
    };

    Node.prototype.unsub = function() {
      var child, _i, _len, _ref, _results;
      _ref = this.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(child.unsub());
      }
      return _results;
    };

    return Node;

  })();

  BinOp = (function(_super) {
    __extends(BinOp, _super);

    function BinOp(arr) {
      this.left = parse(arr[1]);
      this.right = parse(arr[2]);
      this.children = [this.left, this.right];
    }

    return BinOp;

  })(Node);

  Div = (function(_super) {
    __extends(Div, _super);

    function Div() {
      Div.__super__.constructor.apply(this, arguments);
    }

    Div.prototype.render = function() {
      return "\\frac{" + (this.left.render()) + "}{" + (this.right.render()) + "}";
    };

    Div.prototype.compute = function(scope) {
      return this.left.compute(scope) / this.right.compute(scope);
    };

    return Div;

  })(BinOp);

  Mul = (function(_super) {
    __extends(Mul, _super);

    function Mul() {
      Mul.__super__.constructor.apply(this, arguments);
    }

    Mul.prototype.render = function() {
      return "" + (this.left.render()) + "\\cdot " + (this.right.render());
    };

    Mul.prototype.compute = function(scope) {
      return this.left.compute(scope) * this.right.compute(scope);
    };

    return Mul;

  })(BinOp);

  Add = (function(_super) {
    __extends(Add, _super);

    function Add() {
      Add.__super__.constructor.apply(this, arguments);
    }

    Add.prototype.render = function() {
      return "" + (this.left.render()) + "+" + (this.right.render());
    };

    Add.prototype.compute = function(scope) {
      return this.left.compute(scope) + this.right.compute(scope);
    };

    return Add;

  })(BinOp);

  Sub = (function(_super) {
    __extends(Sub, _super);

    function Sub() {
      Sub.__super__.constructor.apply(this, arguments);
    }

    Sub.prototype.render = function() {
      return "" + (this.left.render()) + "-" + (this.right.render());
    };

    Sub.prototype.compute = function(scope) {
      return this.left.compute(scope) - this.right.compute(scope);
    };

    return Sub;

  })(BinOp);

  Exp = (function(_super) {
    __extends(Exp, _super);

    function Exp() {
      Exp.__super__.constructor.apply(this, arguments);
    }

    Exp.prototype.render = function() {
      return "" + (this.left.render()) + "^{" + (this.right.render()) + "}";
    };

    Exp.prototype.compute = function(scope) {
      return Math.pow(this.left.compute(scope), this.right.compute(scope));
    };

    return Exp;

  })(BinOp);

  Lok = (function(_super) {
    __extends(Lok, _super);

    function Lok(arr) {
      this.fname = arr[1];
      this.children = [this.arg = parse(arr[2])];
      this.val = null;
    }

    Lok.prototype.render = function() {
      if (this.val != null) {
        return renderNum(this.val);
      } else {
        return "" + this.fname + "_{" + (this.arg.render()) + "}";
      }
    };

    Lok.prototype.compute = function(scope) {
      return nativeFunctions[this.fname](scope, this.arg);
    };

    Lok.prototype.subsitute = function(scope) {
      this.val = nativeFunctions[this.fname](scope, this.arg);
      return Lok.__super__.subsitute.apply(this, arguments);
    };

    Lok.prototype.unsub = function() {
      return this.val = null;
    };

    return Lok;

  })(BinOp);

  Call = (function(_super) {
    __extends(Call, _super);

    function Call() {
      return Call.__super__.constructor.apply(this, arguments);
    }

    Call.prototype.render = function() {
      if (this.val != null) {
        return renderNum(this.val);
      } else {
        return "" + this.fname + "(" + (this.arg.render()) + ")";
      }
    };

    return Call;

  })(Lok);

  Chem = (function(_super) {
    __extends(Chem, _super);

    function Chem(val) {
      val = val.slice(1, -1);
      this.val = chemical.parse(val);
      this.children = [];
    }

    Chem.prototype._renderArr = function(array) {
      var element, str, _i, _len;
      str = '';
      for (_i = 0, _len = array.length; _i < _len; _i++) {
        element = array[_i];
        if (typeof element[0] === 'string' || element[0] instanceof String) {
          if (element[1] !== 1) {
            str += "" + element[0] + "_" + element[1];
          } else {
            str += element[0];
          }
        } else {
          if (element[1] !== 1) {
            str += "(" + (this._renderArr(element[0])) + ")_" + element[1];
          } else {
            str += element[0];
          }
        }
      }
      return str;
    };

    Chem.prototype.render = function() {
      return this._renderArr(this.val);
    };

    Chem.prototype.compute = function() {
      throw new Error('Cannot compute value of a chemical.');
    };

    return Chem;

  })(Node);

  Neg = (function(_super) {
    __extends(Neg, _super);

    function Neg(arr) {
      this.children = [this.val = parse(arr[1])];
    }

    Neg.prototype.render = function() {
      return "-" + (this.val.render());
    };

    Neg.prototype.compute = function(scope) {
      return -this.val.compute(scope);
    };

    return Neg;

  })(Node);

  renderVar = function(name) {
    var char, count, str, _i, _j, _len;
    str = '';
    count = 0;
    for (_i = 0, _len = name.length; _i < _len; _i++) {
      char = name[_i];
      if (char === '_') {
        str += '_{';
        count += 1;
      } else {
        str += char;
      }
    }
    if (count > 0) {
      for (_j = 1; 1 <= count ? _j <= count : _j >= count; 1 <= count ? _j++ : _j--) {
        str += '}';
      }
    }
    if (str[0] === 'd') {
      return "\\Delta " + str.slice(1);
    } else {
      return str;
    }
  };

  Var = (function(_super) {
    __extends(Var, _super);

    function Var(name) {
      this.name = name;
      this.val = null;
    }

    Var.prototype.render = function() {
      if (this.val != null) {
        return renderNum(this.val);
      } else {
        return renderVar(this.name);
      }
    };

    Var.prototype.compute = function(scope) {
      return scope[this.name];
    };

    Var.prototype.subsitute = function(scope) {
      return this.val = scope[this.name];
    };

    Var.prototype.unsub = function() {
      return this.val = null;
    };

    return Var;

  })(Node);

  Paren = (function(_super) {
    __extends(Paren, _super);

    function Paren(arr) {
      this.children = [this.expr = parse(arr[1])];
    }

    Paren.prototype.render = function() {
      return "(" + (this.expr.render()) + ")";
    };

    Paren.prototype.compute = function(scope) {
      return this.expr.compute(scope);
    };

    return Paren;

  })(Node);

  maxLen = function(str, len) {
    var char, count, rstr, _i, _len;
    rstr = '';
    count = 0;
    for (_i = 0, _len = str.length; _i < _len; _i++) {
      char = str[_i];
      if (char.match(/\d/) != null) {
        rstr += char;
        count++;
      } else {
        rstr += char;
      }
      if (count >= len) {
        break;
      }
    }
    return rstr;
  };

  noplus = function(str) {
    if (str[0] === '+') {
      return str.slice(1);
    } else {
      return str;
    }
  };

  renderNum = function(num) {
    var str;
    str = num.toExponential();
    if (Math.abs(Number(str.slice(str.indexOf('e') + 1))) > 3) {
      return "" + (maxLen(str.slice(0, str.indexOf('e')), 4)) + "\\cdot 10^{" + (noplus(str.slice(str.indexOf('e') + 1))) + "}";
    } else {
      return maxLen(num.toString(), 4);
    }
  };

  Num = (function(_super) {
    __extends(Num, _super);

    function Num(val) {
      this.val = val;
      Num.__super__.constructor.apply(this, arguments);
    }

    Num.prototype.render = function() {
      return renderNum(this.val);
    };

    Num.prototype.compute = function() {
      return this.val;
    };

    return Num;

  })(Node);

  window.parse = function(arr) {
    if (typeof arr === 'number' || arr instanceof Number) {
      return new Num(arr);
    } else if (typeof arr === 'string' || arr instanceof String) {
      if (arr[0] === '{') {
        return new Chem(arr);
      } else {
        return new Var(arr);
      }
    } else {
      switch (arr[0]) {
        case '+':
          return new Add(arr);
        case '-':
          return new Sub(arr);
        case '*':
          return new Mul(arr);
        case '/':
          return new Div(arr);
        case '^':
          return new Exp(arr);
        case ':':
          return new Lok(arr);
        case '-':
          return new Sub(arr);
        case 'UMINUS':
          return new Neg(arr);
        case 'call':
          return new Call(arr);
        case 'PARENS':
          return new Paren(arr);
      }
    }
  };


  /*
   * Native fns
   */

  atomMasses = {
    "H": 1.0079,
    "He": 4.0026,
    "Li": 6.941,
    "Be": 9.0122,
    "B": 10.811,
    "C": 12.0107,
    "N": 14.0067,
    "O": 15.9994,
    "F": 18.9984,
    "Ne": 20.1797,
    "Na": 22.9897,
    "Mg": 24.305,
    "Al": 26.9815,
    "Si": 28.0855,
    "P": 30.9738,
    "S": 32.065,
    "Cl": 35.453,
    "K": 39.0983,
    "Ar": 39.948,
    "Ca": 40.078,
    "Sc": 44.9559,
    "Ti": 47.867,
    "V": 50.9415,
    "Cr": 51.9961,
    "Mn": 54.938,
    "Fe": 55.845,
    "Ni": 58.6934,
    "Co": 58.9332,
    "Cu": 63.546,
    "Zn": 65.39,
    "Ga": 69.723,
    "Ge": 72.64,
    "As": 74.9216,
    "Se": 78.96,
    "Br": 79.904,
    "Kr": 83.8,
    "Rb": 85.4678,
    "Sr": 87.62,
    "Y": 88.9059,
    "Zr": 91.224,
    "Nb": 92.9064,
    "Mo": 95.94,
    "TC": 89,
    "Ru": 101.07,
    "Rh": 102.9055,
    "Pd": 106.42,
    "Ag": 107.8682,
    "Cd": 112.411,
    "In": 114.818,
    "Sn": 118.71,
    "Sb": 121.76,
    "I": 126.9045,
    "Te": 127.6,
    "Xe": 131.293,
    "Cs": 132.9055,
    "Ba": 137.327,
    "La": 138.9055,
    "Ce": 140.116,
    "Pr": 140.9077,
    "Nd": 144.24,
    "Pm": 145,
    "Sm": 150.36,
    "Eu": 151.964,
    "Gd": 157.25,
    "Tb": 158.9253,
    "Dy": 162.5,
    "Ho": 164.9303,
    "Er": 167.259,
    "Tm": 168.9342,
    "Yb": 173.04,
    "Lu": 174.967,
    "Hf": 178.49,
    "Ta": 180.9479,
    "W": 183.84,
    "Re": 186.207,
    "Os": 190.23,
    "Ir": 192.217,
    "Pt": 195.078,
    "Au": 196.9665,
    "Hg": 200.59,
    "Tl": 204.3833,
    "Pb": 207.2,
    "Bi": 208.9804,
    "Po": 209,
    "At": 210,
    "Rn": 222,
    "Fr": 223,
    "Ra": 226,
    "Ac": 227,
    "Pa": 231.0359,
    "Th": 232.0381,
    "Np": 237,
    "U": 238.0289,
    "Am": 243,
    "Pu": 244,
    "Cm": 247,
    "Bk": 247,
    "Cf": 251,
    "Es": 252,
    "Fm": 257,
    "Md": 258,
    "No": 259,
    "Rf": 261,
    "Lr": 262,
    "Db": 262,
    "Bh": 264,
    "Sg": 266,
    "Mt": 268,
    "Rg": 272,
    "Hs": 277
  };

  mm_arr = function(array) {
    var element, total, _i, _len;
    total = 0;
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      element = array[_i];
      if (element[0] in atomMasses) {
        total += atomMasses[element[0]] * element[1];
      } else {
        total += mm_arr(element[0]) * element[1];
      }
    }
    return total;
  };

  nativeFunctions = {
    'mm': function(scope, chem) {
      return mm_arr(chem.val);
    },
    'log': function(scope, arg) {
      return Math.log(arg.compute(scope)) / Math.log(10);
    },
    'ln': function(scope, arg) {
      return Math.log(arg.compute(scope));
    },
    'sqrt': function(scope, arg) {
      return Math.sqrt(arg.compute(scope));
    }
  };


  /*
   * MathJax
   */

  MathJax.Hub.Config({
    displayAlign: 'left'
  });

  intersectZero = function(x1, y1, x2, y2) {
    return x1 - (x1 - x2) / (y1 - y2) * y1;
  };

  solveSecantMethod = function(scope, left, right, variable) {
    var count, newX, solved, x1, x2, y1, y2;
    count = 0;
    solved = false;
    while (!(solved && scope[variable] > 0 || count > 1000)) {
      x1 = scope[variable] = Math.random();
      x2 = Math.random();
      while (!(count > 1000)) {
        scope[variable] = x1;
        y1 = left.compute(scope) - right.compute(scope);
        scope[variable] = x2;
        y2 = left.compute(scope) - right.compute(scope);
        newX = intersectZero(x1, y1, x2, y2);
        x1 = x2;
        if ((Math.abs(newX - x1) < 0.01 * scope[variable] && Math.abs(left.compute(scope) - right.compute(scope)) < .001) || scope[variable] !== scope[variable]) {
          break;
        }
        x2 = newX;
        count += 1;
      }
      count += 1;
      solved = true;
    }
    console.log(scope[variable], count);
    return scope[variable];
  };


  /*
   * UI
   */

  window.onload = function() {
    var changed, input, output, poll;
    input = document.getElementById('input');
    output = document.getElementById('output');
    changed = true;
    input.addEventListener('input', function() {
      return changed = true;
    });
    poll = function() {
      var e, expression, leftExpression, line, lines, oldRender, result, rightExpression, scope, text, variable, _i, _len;
      if (changed) {
        text = '$$\n  \\begin{align*}';
        try {
          lines = input.value.split('\n');
          scope = {};
          for (_i = 0, _len = lines.length; _i < _len; _i++) {
            line = lines[_i];
            if (line.trim().length === 0) {
              text += "\n\\\\";
            } else if (line.slice(0, 2) === '##') {
              text += "\n\n&\\Large{\\textrm{" + line.slice(2) + "}}\n\n\\\\";
            } else if (line[0] === '#') {
              text += "\n\n&\\textrm{" + line.slice(1) + "}\n\n\\\\";
            } else if (line.slice(0, 5) === 'SOLVE') {
              variable = line.slice(5, line.indexOf("|")).trim();
              leftExpression = parse(grammar.parse(line.slice(line.indexOf('|') + 1, line.indexOf('=')).trim()));
              rightExpression = parse(grammar.parse(line.slice(line.indexOf('=') + 1).trim()));
              result = solveSecantMethod(scope, leftExpression, rightExpression, variable);
              console.log(result, renderNum(result));
              text += "&" + (leftExpression.render()) + " = " + (rightExpression.render()) + "; " + (renderVar(variable)) + " = " + (renderNum(result)) + "\n\\\\";
            } else {
              variable = line.slice(0, line.indexOf('=')).trim();
              expression = parse(grammar.parse(line.slice(line.indexOf('=') + 1).trim()));
              text += "&" + (renderVar(variable)) + "\n  = " + (oldRender = expression.render());
              expression.subsitute(scope);
              if (expression.render() !== oldRender) {
                text += "=" + (oldRender = expression.subsitute(scope), expression.render());
              }
              if (renderNum(expression.compute(scope)) !== oldRender) {
                text += "=" + (renderNum(expression.compute(scope)));
              }
              text += '\n\\\\';
              scope[variable] = expression.compute(scope);
            }
          }
          text += '  \\end{align*}\n$$';
          output.innerText = output.textContent = text;
          MathJax.Hub.Queue(["Typeset", MathJax.Hub]);
        } catch (_error) {
          e = _error;
          text = e.stack;
          output.innerText = output.textContent = text;
        }
      }
      changed = false;
      return setTimeout(poll, 2000);
    };
    return poll();
  };

}).call(this);

//# sourceMappingURL=index.js.map
