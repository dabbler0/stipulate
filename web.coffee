define ['./brent-rjs', './text!./units.json', './text!./atoms.json'], (brent, data, atomicData) ->
  exports = {}
  data = JSON.parse data

  atomicData = JSON.parse atomicData

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
        throw new Error 'Cannot subtract two numbers of different units'
      
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
      
      for element, i in result
        displayNum /= desiredUnits[i].number ** element

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
          else top.push "#{desiredUnits[i].name}^{#{element}}"
        else if element < 0
          if element is -1 then bottom.push desiredUnits[i].name
          else bottom.push "#{desiredUnits[i].name}^{#{-element}}"
      
      displayString = displayNum.toPrecision Math.min 21, @sigFigs
      displayString = displayString.replace(/e\+?(\-?\d+)/, ' \\cdot 10^{$1}')
      
      if bottom.length > 0
        if top.length > 0
          return "#{displayString} \\frac{#{top.join(' ')}}{#{bottom.join(' ')}}"
        else
          return "\\frac{#{displayString}}{#{bottom.join(' ')}}"
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

    render: (usingUnits) -> "#{@left.render(usingUnits)} #{@op} #{@right.render(usingUnits)}"

    renderSubbed: (scope, usingUnits) -> "#{@left.renderSubbed(scope, usingUnits)} #{@op} #{@right.renderSubbed(scope, usingUnits)}"

  class AddExpression extends BinaryOperation
    constructor: -> @op = '+'; super

    compute: (scope, usingUnits) -> @left.compute(scope, usingUnits).add @right.compute(scope, usingUnits)

  class SubExpression extends BinaryOperation
    constructor: -> @op = '-'; super

    compute: (scope, usingUnits) -> @left.compute(scope, usingUnits).sub @right.compute(scope, usingUnits)

  class MulExpression extends BinaryOperation
    constructor: -> @op = '\\cdot'; super

    compute: (scope, usingUnits) -> @left.compute(scope, usingUnits).mul @right.compute(scope, usingUnits)

  class DivExpression extends BinaryOperation
    constructor: -> super

    compute: (scope, usingUnits) -> @left.compute(scope, usingUnits).div @right.compute(scope, usingUnits)

    render: (usingUnits) -> "\\frac{#{@left.render(usingUnits)}}{#{@right.render(usingUnits)}}"
    
    renderSubbed: (scope, usingUnits) -> "\\frac{#{@left.renderSubbed(scope, usingUnits)}}{#{@right.renderSubbed(scope, usingUnits)}}"

  class ExpExpression extends BinaryOperation
    constructor: -> super

    compute: (scope, usingUnits) -> @left.compute(scope, usingUnits).exp @right.compute(scope, usingUnits)

    render: (usingUnits) -> "#{@left.render(usingUnits)}^{#{@right.render(usingUnits)}}"
    
    renderSubbed: (scope, usingUnits) -> "#{@left.renderSubbed(scope, usingUnits)}^{#{@right.renderSubbed(scope, usingUnits)}}"

  class NumExpression extends Expression
    constructor: (array) ->
      @val = UnitNum.fromArray array

    compute: -> @val

    render: (usingUnits) -> @val.express usingUnits

    renderSubbed: (scope, usingUnits) -> @render(usingUnits)

  renderVar = (name) -> name.replace /\\d/g, '\\Delta '

  class VarExpression extends Expression
    constructor: (array) ->
      @name = array[1]

    compute: (scope, usingUnits) ->
      if @name of scope then scope[@name]
      else if @name of units then new UnitNum 1, units[@name].units
      else
        throw new Error "Cannot find variable #{@name}"

    render: (usingUnits) -> renderVar @name

    renderSubbed: (scope, usingUnits) ->
      if @name of scope then scope[@name].express usingUnits
      else if @name of units then @name
      else
        throw new Error "Cannot find variable #{@name}"

  class CallExpression extends Expression
    constructor: (array) ->
      @fname = array[1]
      @argument = Expression.fromArray array[2]

    compute: (scope, usingUnits) -> functionScope[@fname] scope, usingUnits, @argument.compute scope, usingUnits

    render: (usingUnits) -> "#{@fname}(#{@argument.render(usingUnits)})"

    renderSubbed: (scope, usingUnits) -> functionScope[@fname](scope, usingUnits, @argument.compute(scope, usingUnits)).express usingUnits

  class ParenExpression extends Expression
    constructor: (array) ->
      @value = Expression.fromArray array[1]

    compute: (scope, usingUnits) -> @value.compute scope, usingUnits

    render: (usingUnits) -> "(#{@value.render(usingUnits)})"

    renderSubbed: (scope, usingUnits) -> "(#{@value.renderSubbed(scope, usingUnits)})"

  class NegExpression extends Expression
    constructor: (array) ->
      @value = Expression.fromArray array[1]

    compute: (scope, usingUnits) -> @value.compute(scope, usingUnits).mul new UnitNum -1, UNITLESS

    render: (usingUnits) -> "-#{@value.render(usingUnits)}"

    renderSubbed: (scope, usingUnits) -> "-#{@value.renderSubbed(scope, usingUnits)}"
  
  renderChemicalArray = (arr) ->
    res = []
    for element in arr
      if element[0] of atomicData
        if element[1] is 1
          res.push element[0]
        else
          res.push "#{element[0]}_{#{element[1]}}"
      else
        res.push "(#{renderChemicalArray(element[0])})_{#{element[1]}}"

    return res.join ' '

  class StringExpression extends Expression
    constructor: (array) ->
      @str = array[1][1..-2]

    compute: (scope, usingUnits) -> @str

    render: ->
      try
        return renderChemicalArray chemical.parse(@str).chem
      catch
        return @str

    renderSubbed: -> @render()

  molarMassOfArray = (array) ->
    mass = 0
    for element in array
      if element[0] of atomicData
        mass += atomicData[element[0]] * element[1]
      else
        mass += molarMassOfArray(element[0]) * element[1]

    return mass


  functionScope =
    'ln': (scope, desiredUnits, n) -> new UnitNum Math.log(n.terms(desiredUnits).displayNum), UNITLESS, n.sigFigs
    'log': (scope, desiredUnits, n) ->
      new UnitNum Math.log(n.terms(desiredUnits).displayNum) / Math.log(10), UNITLESS, n.sigFigs
    'mm': (scop, desiredUnits, n) ->
      new UnitNum molarMassOfArray(chemical.parse(n).chem) / 1000 , {
        'kg': 1
        'm': 0
        's': 0
        'mol': -1
        'A': 0
        'K': 0
      }, 4
  
  parseMap =
    '+': AddExpression
    '-': SubExpression
    '/': DivExpression
    '*': MulExpression
    '^': ExpExpression
    'UMINUS': NegExpression
    'STRING': StringExpression
    'UNIT': NumExpression
    'VARIABLE': VarExpression
    'CALL': CallExpression
    'PARENS': ParenExpression

  Expression.fromArray = (array) -> new parseMap[array[0]] array
  
  exports.ExecutionContext = class ExecutionContext
    constructor: (usingUnits = ['kg', 'm', 's', 'mol', 'A', 'K'], @scope = {}) ->
      @usingUnits = (units[key] for key in usingUnits)

    setUnits: (units) ->
      @usingUnits = (units[key] for key in usingUnits)

    execute: (line) ->
      parsed = grammar.parse line

      rstr = ''

      if parsed[0] is 'ASSIGN'
        testNumber = Expression.fromArray parsed[2]
        last_ = ''
        rstr += renderVar(parsed[1])
        if (last_ isnt (last_ = testNumber.render(@usingUnits)))
          rstr += '=' + last_
        if (last_ isnt (last_ = testNumber.renderSubbed(@scope, @usingUnits)))
          rstr += '=' + last_
        @scope[parsed[1]] = testNumber.compute @scope, @usingUnits

        if (last_ isnt (last_ = @scope[parsed[1]].express @usingUnits))
          rstr += '=' + last_

      else if parsed[0] is 'SOLVE'
        left = Expression.fromArray parsed[4]
        right = Expression.fromArray parsed[5]

        if parsed[6]?
          parsedUnit = parseUnit(parsed[6])
          unitMultiplier = parsedUnit.number
          unit = parsedUnit.units
        else
          unitNultiplier = 1
          unit = UNITLESS
        
        brent.brent ((x) =>
          @scope[parsed[1]] = new UnitNum x * unitMultiplier, unit, 4
          return left.compute(@scope).num - right.compute(@scope, @usingUnits).num
        ), Number(parsed[2]), Number(parsed[3])

        rstr += "#{left.render(@usingUnits)} = #{right.render(@usingUnits)}; "
        rstr += "#{renderVar(parsed[1])} = #{@scope[parsed[1]].express @usingUnits}"

      else
        testNumber = Expression.fromArray parsed
        rstr += testNumber.render(@usingUnits)
        rstr += '=' + testNumber.renderSubbed(@scope, @usingUnits)
        rstr += '=' + testNumber.compute(@scope, @usingUnits).express @usingUnits

      return rstr

  return exports
