fs = require 'fs'
numeric = require './numeric.min'
brent = require './brent'
readline = require 'readline'

fs.readFile 'units.json', (err, data) ->
  data = JSON.parse data.toString()
  units = data.units
  fundamentals = data.fundamentals

  UNITLESS = {}

  for fundamental in fundamentals then UNITLESS[fundamental] = 0

  objEquals = (a, b) ->
    for key, val of a then if b[key] isnt val then return false
    for key, val of b then if a[key] isnt val then return false

    return true

  checkObj = (a, f) ->
    for key, val of a then unless f(val) then return false
    return true

  applyObj = (a, f) ->
    result = {}
    for key of a then result[key] = f a[key]
    return result

  compositeObj = (a, b, f) ->
    result = {}

    for key of a
      result[key] = f a[key], b[key]

    return result

  parseUnit = (parsed) ->
    top = parsed[0]
    bottom = parsed[1]

    result = {}
    resultNum = 1

    for fundamental in fundamentals
      result[fundamental] = 0

    if top? then for unit in top
      for referredFundamental, val of units[unit[0]].units
        result[referredFundamental] += val * unit[1]
      resultNum *= units[unit[0]].number ** unit[1]
    
    if bottom? then for unit in bottom
      for referredFundamental, val of units[unit[0]].units
        result[referredFundamental] -= val * unit[1]
      resultNum /= units[unit[0]].number ** unit[1]

    return {
      number: resultNum
      units: result
    }

  exports.UnitNum = class UnitNum
    constructor: (@num, @unit) ->
    
    add: (other) ->
      unless objEquals @unit, other.unit
        throw new Error 'Cannot add two numbers of different units'
      
      return new UnitNum(@num + other.num, @unit)
    
    sub: (other) ->
      unless objEquals @unit, other.unit
        throw new Error 'Cannot add two numbers of different units'
      
      return new UnitNum(@num - other.num, @unit)
    
    mul: (other) ->
      return new UnitNum(@num * other.num, compositeObj(@unit, other.unit, (a, b) -> a + b))

    div: (other) ->
      return new UnitNum(@num / other.num, compositeObj(@unit, other.unit, (a, b) -> a - b))
    
    # Discard exp units.
    exp: (other) ->
      return new UnitNum(@num ** other.num, applyObj(@unit, (x) -> x * other.num))
    
    terms: (desiredUnits) ->
      system = []
      vals = []

      for fundamental of @unit
        row = []
        for unit in desiredUnits
          row.push unit.units[fundamental]

        vals.push @unit[fundamental]

        system.push row
      
      result = numeric.solve system, vals
      
      displayNum = @num

      return {
        displayNum: displayNum
        result: result
      }

    express: (desiredUnits) ->
      {displayNum, result} = @terms desiredUnits
      
      top = []; bottom = []
      for element, i in result
        if element > 0
          if element is 1 then top.push desiredUnits[i].name
          else top.push "#{desiredUnits[i].name}^#{element}"
        else if element < 0
          if element is -1 then bottom.push desiredUnits[i].name
          else bottom.push "#{desiredUnits[i].name}^#{-element}"

        displayNum /= desiredUnits[i].number ** element
      
      if bottom.length > 0
        if top.length > 0
          return "#{displayNum} \\frac{#{top.join(' ')}}/{#{bottom.join(' ')}}"
        else
          return "\\frac{#{displayNum}}/{#{bottom.join(' ')}}"
      else if top.length > 0
        return "#{displayNum} #{top.join(' ')}"
      else
        return displayNum.toString()

  UnitNum.fromArray = (array) ->
    unless array[0] is 'UNIT'
      throw new Error 'Array is not of desired UNIT type.'
    
    num = array[1]

    unit = parseUnit array[2]

    num *= unit.number

    unit.number = 1

    return new UnitNum num, unit.units
  
  # Expressions
  # ===========

  class Expression
    constructor: ->

  class BinaryOperation extends Expression
    constructor: (array) ->
      @left = Expression.fromArray array[1]
      @right = Expression.fromArray array[2]

  class AddExpression extends BinaryOperation
    constructor: -> super

    compute: (scope) -> @left.compute(scope).add @right.compute(scope)

  class SubExpression extends BinaryOperation
    constructor: -> super

    compute: (scope) -> @left.compute(scope).sub @right.compute(scope)

  class MulExpression extends BinaryOperation
    constructor: -> super

    compute: (scope) -> @left.compute(scope).mul @right.compute(scope)

  class DivExpression extends BinaryOperation
    constructor: -> super

    compute: (scope) -> @left.compute(scope).div @right.compute(scope)

  class ExpExpression extends BinaryOperation
    constructor: -> super

    compute: (scope) -> @left.compute(scope).exp @right.compute(scope)

  class NumExpression extends Expression
    constructor: (array) ->
      @val = UnitNum.fromArray array

    compute: -> @val

  class VarExpression extends Expression
    constructor: (array) ->
      @name = array[1]

    compute: (scope) ->
      if @name of scope then scope[@name]
      else if @name of units then new UnitNum 1, units[@name].units
      else
        throw new Error "Cannot find variable #{@name}"

  class CallExpression extends Expression
    constructor: (array) ->
      @fname = array[1]
      @argument = Expression.fromArray array[2]

    compute: (scope) -> functionScope[@fname] @argument.compute scope

  class ParenExpression extends Expression
    constructor: (array) ->
      @value = Expression.fromArray array[1]

    compute: (scope) -> @value.compute scope

  functionScope =
    'ln': (n) -> new UnitNum Math.log(n.num), UNITLESS
  
  parseMap =
    '+': AddExpression
    '-': SubExpression
    '/': DivExpression
    '*': MulExpression
    '^': ExpExpression
    'UNIT': NumExpression
    'VARIABLE': VarExpression
    'CALL': CallExpression
    'PARENS': ParenExpression

  Expression.fromArray = (array) -> new parseMap[array[0]] array

  # Test:
  grammar = require './grammar'
  
  iface = readline.createInterface
    input: process.stdin
    output: process.stdout

  iface.setPrompt '> ', 2
  iface.prompt()

  scope = {}

  usingUnits = (units[key] for key in ['g', 'm', 's', 'mol', 'A', 'K'])
  
  iface.on 'line', (answer) ->
    parsed = grammar.parse answer
    if parsed[0] is 'ASSIGN'
      testNumber = Expression.fromArray parsed[2]
      scope[parsed[1]] = testNumber.compute scope
      console.log scope[parsed[1]].express usingUnits
    else if parsed[0] is 'SOLVE'
      left = Expression.fromArray parsed[4]
      right = Expression.fromArray parsed[5]
      brent.brent ((x) ->
        scope[parsed[1]] = new UnitNum x, UNITLESS
        return left.compute(scope).num - right.compute(scope).num
      ), Number(parsed[2]), Number(parsed[3])

      console.log scope[parsed[1]].express usingUnits
    else
      testNumber = Expression.fromArray parsed
      console.log testNumber.compute(scope).express usingUnits
      
    iface.prompt()

  process.on 'uncaughtException', (e) ->
    console.log e.stack
    iface.prompt()
