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
    constructor: (@num, @unit, @sigFigs = Infinity) ->
    
    add: (other) ->
      unless objEquals @unit, other.unit
        throw new Error 'Cannot add two numbers of different units'
      
      lastDigit = Math.floor(Math.log(@num)/Math.log(10)) - @sigFigs
      otherLastDigit = Math.floor(Math.log(other.num)/Math.log(10)) - other.sigFigs

      resultFirstDigit = Math.floor Math.log(@num + other.num)/Math.log(10)
      
      return new UnitNum(@num + other.num, @unit, resultFirstDigit - Math.max(lastDigit, otherLastDigit))
    
    sub: (other) ->
      unless objEquals @unit, other.unit
        throw new Error 'Cannot add two numbers of different units'
      
      lastDigit = Math.floor(Math.log(@num)/Math.log(10)) - @sigFigs
      otherLastDigit = Math.floor(Math.log(other.num)/Math.log(10)) - other.sigFigs

      resultFirstDigit = Math.floor Math.log(@num - other.num)/Math.log(10)
      
      return new UnitNum(@num - other.num, @unit, resultFirstDigit - Math.max(lastDigit, otherLastDigit))
    
    mul: (other) ->
      return new UnitNum(@num * other.num, compositeObj(@unit, other.unit, (a, b) -> a + b), Math.min(other.sigFigs, @sigFigs))

    div: (other) ->
      return new UnitNum(@num / other.num, compositeObj(@unit, other.unit, (a, b) -> a - b), Math.min(other.sigFigs, @sigFigs))
    
    # Discard exp units.
    exp: (other) ->
      return new UnitNum(@num ** other.num, applyObj(@unit, (x) -> x * other.num), @sigFigs)
    
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
      
      displayString = displayNum.toPrecision Math.min 21, @sigFigs
      displayString = displayString.replace(/e\+?(\-?\d+)/, ' \\cdot 10^{$1}')
      
      if bottom.length > 0
        if top.length > 0
          return "#{displayString} \\frac{#{top.join(' ')}}/{#{bottom.join(' ')}}"
        else
          return "\\frac{#{displayString}}/{#{bottom.join(' ')}}"
      else if top.length > 0
        return "#{displayString} #{top.join(' ')}"
      else
        return displayString
  
  getSigFigs = (string) ->
    string = string[..string.indexOf('e')]

    [first, last] = string.split '.'

    if last?
      return first.length + last.length
    else
      result = /[1-9]0*$/.exec string
      if result? and result.index >= 0 then return result.index + 1
      else return first.length

  UnitNum.fromArray = (array) ->
    unless array[0] is 'UNIT'
      throw new Error 'Array is not of desired UNIT type.'
    
    num = Number(array[1])

    unit = parseUnit array[2]

    num *= unit.number

    unit.number = 1

    return new UnitNum num, unit.units, getSigFigs array[1]
  
  # Expressions
  # ===========

  class Expression
    constructor: ->

  class BinaryOperation extends Expression
    constructor: (array) ->
      @left = Expression.fromArray array[1]
      @right = Expression.fromArray array[2]

    render: -> "#{@left.render()} #{@op} #{@right.render()}"

    renderSubbed: (scope) -> "#{@left.renderSubbed(scope)} #{@op} #{@right.renderSubbed(scope)}"

  class AddExpression extends BinaryOperation
    constructor: -> @op = '+'; super

    compute: (scope) -> @left.compute(scope).add @right.compute(scope)

  class SubExpression extends BinaryOperation
    constructor: -> @op = '-'; super

    compute: (scope) -> @left.compute(scope).sub @right.compute(scope)

  class MulExpression extends BinaryOperation
    constructor: -> @op = '\\cdot'; super

    compute: (scope) -> @left.compute(scope).mul @right.compute(scope)

  class DivExpression extends BinaryOperation
    constructor: -> super

    compute: (scope) -> @left.compute(scope).div @right.compute(scope)

    render: -> "\\frac{#{@left.render()}}{#{right.render()}}"
    
    renderSubbed: (scope) -> "\\frac{#{@left.renderSubbed(scope)}}{#{right.renderSubbed(scope)}}"

  class ExpExpression extends BinaryOperation
    constructor: -> super

    compute: (scope) -> @left.compute(scope).exp @right.compute(scope)

    render: -> "#{@left.render()}^{#{right.render()}}"
    
    renderSubbed: (scope) -> "#{@left.renderSubbed(scope)}^{#{right.renderSubbed(scope)}}"

  class NumExpression extends Expression
    constructor: (array) ->
      @val = UnitNum.fromArray array

    compute: -> @val

    render: -> @val.express usingUnits

    renderSubbed: -> @render()

  class VarExpression extends Expression
    constructor: (array) ->
      @name = array[1]

    compute: (scope) ->
      if @name of scope then scope[@name]
      else if @name of units then new UnitNum 1, units[@name].units
      else
        throw new Error "Cannot find variable #{@name}"

    render: -> @name

    renderSubbed: (scope) ->
      if @name of scope then scope[@name].express usingUnits
      else if @name of units then @name
      else
        throw new Error "Cannot find variable #{@name}"

  class CallExpression extends Expression
    constructor: (array) ->
      @fname = array[1]
      @argument = Expression.fromArray array[2]

    compute: (scope) -> functionScope[@fname] @argument.compute scope

    render: -> "#{@fname}(#{@argument.render()})"

    renderSubbed: (scope) -> functionScope[@fname](@argument.compute(scope)).express usingUnits

  class ParenExpression extends Expression
    constructor: (array) ->
      @value = Expression.fromArray array[1]

    compute: (scope) -> @value.compute scope

    render: -> "(#{@value.render()})"

    renderSubbed: (scope) -> "(#{@value.renderSubbed(scope)})"

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
    console.log parsed
    if parsed[0] is 'ASSIGN'
      testNumber = Expression.fromArray parsed[2]
      console.log '=', testNumber.render()
      console.log '=', testNumber.renderSubbed(scope)
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
      console.log '=', testNumber.render()
      console.log '=', testNumber.renderSubbed(scope)
      console.log testNumber.compute(scope).express usingUnits
      
    iface.prompt()

  process.on 'uncaughtException', (e) ->
    console.log e.stack
    iface.prompt()
