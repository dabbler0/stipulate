# Copyright (c) 2014 Anthony Bau
# MIT License

###
# OOP
###

class Node
  constructor: -> @children = []

  subsitute: (scope) ->
    child.subsitute scope for child in @children

  unsub: ->
    child.unsub() for child in @children

class BinOp extends Node
  constructor: (arr) ->
    @left = parse arr[1]
    @right = parse arr[2]

    @children = [@left, @right]

class Div extends BinOp
  constructor: -> super

  render: ->
    "\\frac{#{@left.render()}}{#{@right.render()}}"

  compute: (scope) ->
    @left.compute(scope).div @right.compute(scope)

class Mul extends BinOp
  constructor: -> super

  render: ->
    "#{@left.render()}\\cdot #{@right.render()}"

  compute: (scope) ->
    @left.compute(scope).mul @right.compute(scope)

class Add extends BinOp
  constructor: -> super
  
  render: ->
    "#{@left.render()}+#{@right.render()}"

  compute: (scope) ->
    @left.compute(scope).add @right.compute(scope)

class Sub extends BinOp
  constructor: -> super
  
  render: ->
    "#{@left.render()}-#{@right.render()}"

  compute: (scope) ->
    @left.compute(scope).sub @right.compute(scope)

class Exp extends BinOp
  constructor: -> super

  render: ->
    "#{@left.render()}^{#{@right.render()}}"

  compute: (scope) ->
    @left.compute(scope).exp @right.compute(scope)

class Lok extends BinOp
  constructor: (arr) ->
    @fname = arr[1]
    @children = [
      @arg = parse arr[2]
    ]
    @val = null

  render: ->
    if @val? then renderNum @val else "#{renderVar(@fname)}_{#{@arg.render()}}"

  compute: (scope) -> nativeFunctions[@fname] scope, @arg

  subsitute: (scope) ->
    @val = nativeFunctions[@fname] scope, @arg
    super

  unsub: -> @val = null

class Call extends Lok
  render: ->
    if @val? then renderNum @val else "#{@fname}(#{@arg.render()})"

class Chem extends Node
  constructor: (val) ->
    @str = val = val[1..-2]

    try
      {chem:@val, state:@state} = chemical.parse val

    @children = []

  _renderArr: (array) ->
    str = ''
    for element in array
      if typeof element[0] is 'string' or element[0] instanceof String
        if element[1] isnt 1
          str += "#{element[0]}_#{element[1]}"
        else
          str += element[0]
      else
        if element[1] isnt 1
          str += "(#{@_renderArr element[0]})_#{element[1]}"
        else
          str += element[0]
    return str

  render: -> @_renderArr(@val) + (@state ? '')

  compute: ->
    throw new Error 'Cannot compute value of a chemical.'

class Neg extends Node
  constructor: (arr) ->
    @children = [@val = parse arr[1]]

  render: ->
    "-#{@val.render()}"

  compute: (scope) ->
    @val.compute(scope).mul new UnitNum -1, {}

renderVar = (name) ->
  str = ''
  count = 0
  for char in name
    if char is '_'
      str += '_{'
      count += 1
    else
      str += char

  if count > 0 then str += '}' for [1..count]

  if str[0] is 'd' then "\\Delta #{str[1..]}"
  else str


class Var extends Node
  constructor: (@name) ->
    @val = null

  render: ->
    if @val? then renderNum @val
    else renderVar @name
  
  compute: (scope) ->
    if @name of scope then scope[@name]
    else
      if @name of unitConversions
        return unitConversions[@name]
      else
        unit = {}
        unit[@name] = 1
        new UnitNum 1, unit

  subsitute: (scope) -> @val = scope[@name]

  unsub: -> @val = null

class Paren extends Node
  constructor: (arr) ->
    @children = [@expr = parse arr[1]]

  render: -> "(#{@expr.render()})"

  compute: (scope) -> @expr.compute scope

maxLen = (str, len) ->
  rstr = ''
  count = 0
  for char in str
    if char.match(/\d/)?
      rstr += char
      count++
    else rstr += char

    if count >= len then break

  return rstr

noplus = (str) ->
  if str[0] is '+' then return str[1..]
  else return str

renderNum = (num) ->
  str = num.val.toExponential()
  if Math.abs(Number(str[str.indexOf('e')+1...])) > 3
    return "#{maxLen(str[...str.indexOf('e')], 4)}\\cdot 10^{#{noplus(str[str.indexOf('e')+1...])}}" + num.renderUnits()
  else
    return maxLen(num.val.toString(), 4) + num.renderUnits()

class UnitNum
  constructor: (@val, @units) ->

  add: (other) -> new UnitNum other.val + @val, @units
  sub: (other) -> new UnitNum @val - other.val, @units
  mul: (other) ->
    unitsDict = {}
    
    for unit of @units
      unitsDict[unit] = @units[unit]

    for unit of other.units
      unitsDict[unit] ?= 0
      unitsDict[unit] += other.units[unit]
    
    return new UnitNum other.val * @val, unitsDict
  
  div: (other) ->
    unitsDict = {}
    
    for unit of @units
      unitsDict[unit] = @units[unit]

    for unit of other.units
      unitsDict[unit] ?= 0
      unitsDict[unit] -= other.units[unit]
    
    return new UnitNum @val / other.val, unitsDict
  
  exp: (other) ->
    if Object.keys(other.units).length is 0
      unitsDict = {}
      for unit of @units
        unitsDict[unit] = @units[unit] * other.val

      return new UnitNum @val ** other.val, unitsDict
    else
      return new UnitNum @val ** other.val, {}

  renderUnits: ->
    top = []
    bottom = []
    for unit, p of @units
      if p is 1
        top.push unit
      else if p is -1
        bottom.push unit
      else if p > 0
        top.push "#{unit}^#{p}"
      else if p < 0
        bottom.push "#{unit}^#{-p}"
    
    if bottom.length > 0
      if top.length > 0
        return "\\frac{#{top.join(' ')}}{#{bottom.join(' ')}}"
      else return "\\frac{1}{#{bottom.join(' ')}}"
    else if top.length > 0
      return top.join ' '
    else return ''

unitConversions =
  'M': new UnitNum 1, {mol: 1, L: -1}
  'torr': new UnitNum 1/760, {atm: 1}

class Num extends Node
  constructor: (@val) -> super

  render: -> renderNum new UnitNum @val, {}
  
  compute: -> new UnitNum @val, {}

window.parse = (arr) ->
  if typeof arr is 'number' or arr instanceof Number
    new Num arr
  else if typeof arr is 'string' or arr instanceof String
    if arr[0] is '{' then return new Chem arr
    else new Var arr
  else switch arr[0]
    when '+' then new Add arr
    when '-' then new Sub arr
    when '*' then new Mul arr
    when '/' then new Div arr
    when '^' then new Exp arr
    when ':' then new Lok arr
    when '-' then new Sub arr
    when 'UMINUS' then new Neg arr
    when 'call' then new Call arr
    when 'PARENS' then new Paren arr

###
# Native fns
###

# oops hardocded everything
atomMasses =
  "H": 1.0079
  "He": 4.0026
  "Li": 6.941
  "Be": 9.0122
  "B": 10.811
  "C": 12.0107
  "N": 14.0067
  "O": 15.9994
  "F": 18.9984
  "Ne": 20.1797
  "Na": 22.9897
  "Mg": 24.305
  "Al": 26.9815
  "Si": 28.0855
  "P": 30.9738
  "S": 32.065
  "Cl": 35.453
  "K": 39.0983
  "Ar": 39.948
  "Ca": 40.078
  "Sc": 44.9559
  "Ti": 47.867
  "V": 50.9415
  "Cr": 51.9961
  "Mn": 54.938
  "Fe": 55.845
  "Ni": 58.6934
  "Co": 58.9332
  "Cu": 63.546
  "Zn": 65.39
  "Ga": 69.723
  "Ge": 72.64
  "As": 74.9216
  "Se": 78.96
  "Br": 79.904
  "Kr": 83.8
  "Rb": 85.4678
  "Sr": 87.62
  "Y": 88.9059
  "Zr": 91.224
  "Nb": 92.9064
  "Mo": 95.94
  "TC": 89
  "Ru": 101.07
  "Rh": 102.9055
  "Pd": 106.42
  "Ag": 107.8682
  "Cd": 112.411
  "In": 114.818
  "Sn": 118.71
  "Sb": 121.76
  "I": 126.9045
  "Te": 127.6
  "Xe": 131.293
  "Cs": 132.9055
  "Ba": 137.327
  "La": 138.9055
  "Ce": 140.116
  "Pr": 140.9077
  "Nd": 144.24
  "Pm": 145
  "Sm": 150.36
  "Eu": 151.964
  "Gd": 157.25
  "Tb": 158.9253
  "Dy": 162.5
  "Ho": 164.9303
  "Er": 167.259
  "Tm": 168.9342
  "Yb": 173.04
  "Lu": 174.967
  "Hf": 178.49
  "Ta": 180.9479
  "W": 183.84
  "Re": 186.207
  "Os": 190.23
  "Ir": 192.217
  "Pt": 195.078
  "Au": 196.9665
  "Hg": 200.59
  "Tl": 204.3833
  "Pb": 207.2
  "Bi": 208.9804
  "Po": 209
  "At": 210
  "Rn": 222
  "Fr": 223
  "Ra": 226
  "Ac": 227
  "Pa": 231.0359
  "Th": 232.0381
  "Np": 237
  "U": 238.0289
  "Am": 243
  "Pu": 244
  "Cm": 247
  "Bk": 247
  "Cf": 251
  "Es": 252
  "Fm": 257
  "Md": 258
  "No": 259
  "Rf": 261
  "Lr": 262
  "Db": 262
  "Bh": 264
  "Sg": 266
  "Mt": 268
  "Rg": 272
  "Hs": 277

mm_arr = (array) ->
  total = 0
  for element in array
    if element[0] of atomMasses
      total += atomMasses[element[0]] * element[1]
    else
      total += mm_arr(element[0]) * element[1]
  
  return total

nativeFunctions =
  'mm': (scope, chem) -> new UnitNum mm_arr(chem.val), {"g": 1, "mol": -1}
  'log': (scope, arg) -> new UnitNum (Math.log(arg.compute(scope).val) / Math.log(10)), {}
  'ln': (scope, arg) -> new UnitNum Math.log(arg.compute(scope).val), {}
  'sqrt': (scope, arg) -> arg.compute(scope).exp 0.5

###
# MathJax
###

MathJax.Hub.Config {
  displayAlign: 'left'
}

intersectZero = (x1, y1, x2, y2) ->
  return x1 - (x1 - x2) / (y1 - y2) * y1

solveSecantMethod = (scope, left, right, variable) ->
  count = 0
  solved = false
  scope[variable] = new UnitNum 0, {}
  until solved and scope[variable].val > 0 or count > 1000
    x1 = scope[variable].val = Math.random()
    x2 = Math.random()
    until count > 1000
      scope[variable].val = x1
      y1 = left.compute(scope).val - right.compute(scope).val

      scope[variable].val = x2
      y2 = left.compute(scope).val - right.compute(scope).val

      newX = intersectZero(x1, y1, x2, y2)
      
      x1 = x2

      if (Math.abs(newX - x1) < 0.01 * scope[variable].val and Math.abs(left.compute(scope).val - right.compute(scope).val) < .001) or scope[variable].val isnt scope[variable].val
        break

      x2 = newX

      count += 1

    count += 1
    solved = true

  return scope[variable]

unitConversions =
  'M': new UnitNum 1, {mol: 1, L: -1}
  'kJ': new UnitNum 1000, {J: 1}
  'mL': new UnitNum .001, {L: 1}

$.ajax
  url: 'hf.json'
  dataType: 'json'
  success: (data) ->
    nativeFunctions['dHf'] = (scope, chem) -> new UnitNum data[chem.str] * 1000, {J: 1}
###
# UI
###
window.onload = ->

  input = document.getElementById 'input'
  output = document.getElementById 'output'
  
  changed = true
  input.addEventListener 'input', ->
    changed = true
  
  poll = ->
    if changed
      text = '''
        $$
          \\begin{align*}
      '''
      try
        lines = input.value.split '\n'
        scope = {}
        for line in lines
          if line.trim().length is 0
            text += "\n\\\\"
          else if line[0..1] is '##'
            text += "\n\n&\\Large{\\textrm{#{line[2..]}}}\n\n\\\\"
          else if line[0] is '#'
            text += "\n\n&\\textrm{#{line[1..]}}\n\n\\\\"
          else if line[0..4] is 'SOLVE'
            variable = line[5...line.indexOf("|")].trim()
            leftExpression = parse grammar.parse line[line.indexOf('|')+1...line.indexOf('=')].trim()
            rightExpression = parse grammar.parse line[line.indexOf('=')+1...].trim()

            result = solveSecantMethod scope, leftExpression, rightExpression, variable

            text += """
              &#{leftExpression.render()} = #{rightExpression.render()}; #{renderVar(variable)} = #{renderNum(result)}\n\\\\
            """
          else
            variable = line[...line.indexOf('=')].trim()
            expression = parse grammar.parse line[line.indexOf('=')+1...].trim()
            text += """
              &#{renderVar(variable)}
                = #{oldRender = expression.render()}
            """
            expression.subsitute scope
            if expression.render() isnt oldRender
              text += """
                =#{oldRender = expression.subsitute(scope);expression.render()}
              """
            if renderNum(expression.compute(scope)) isnt oldRender
              text += """
                =#{renderNum(expression.compute(scope))}
              """

            text += '\n\\\\'

            scope[variable] = expression.compute scope

        text += '''
            \\end{align*}
          $$
        '''
      
        output.innerText = output.textContent = text

        MathJax.Hub.Queue ["Typeset", MathJax.Hub]
      catch e
        text = e.stack

        output.innerText = output.textContent = text

    changed = false
    setTimeout poll, 2000

  poll()

  window.getLatex = ->
    text = '''
      \\documentclass{article}
      \\begin{document}
    '''
    try
      lines = input.value.split '\n'
      scope = {}
      for line in lines
        if line.trim().length is 0
          text += "\n"
        else if line[0..1] is '##'
          text += "\n\n\\Large{\\textrm{#{line[2..]}}}\n\n"
        else if line[0] is '#'
          text += "\n\n\\textrm{#{line[1..]}}\n\n"
        else if line[0..4] is 'SOLVE'
          variable = line[5...line.indexOf("|")].trim()
          leftExpression = parse grammar.parse line[line.indexOf('|')+1...line.indexOf('=')].trim()
          rightExpression = parse grammar.parse line[line.indexOf('=')+1...].trim()

          result = solveSecantMethod scope, leftExpression, rightExpression, variable

          text += """
            $$#{leftExpression.render()} = #{rightExpression.render()}; #{renderVar(variable)} = #{renderNum(result)}$$\n
          """
        else
          variable = line[...line.indexOf('=')].trim()
          expression = parse grammar.parse line[line.indexOf('=')+1...].trim()
          text += """
            $$#{renderVar(variable)} = #{oldRender = expression.render()}
          """
          expression.subsitute scope
          if expression.render() isnt oldRender
            text += """
              =#{oldRender = expression.subsitute(scope);expression.render()}
            """
          if renderNum(expression.compute(scope)) isnt oldRender
            text += """
              =#{renderNum(expression.compute(scope))}
            """

          text += '$$\n'

          scope[variable] = expression.compute scope

      text += '''
          \\end{document}
      '''
