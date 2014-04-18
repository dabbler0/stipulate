parser = require './units'
fs = require 'fs'

fs.readFile process.argv[2], (err, data) ->
  lines = data.toString().split '\n'

  fundamentals = lines.shift().split ' '
  units = {}

  for fundamental in fundamentals
    newFundamental = {}
    for subFundamental in fundamentals
      newFundamental[subFundamental] = 0
    newFundamental[fundamental] = 1

    units[fundamental] = {
      name: fundamental
      number: 1
      units: newFundamental
    }

  for line in lines
    if line.trim().length is 0 or line[0] is '#' then continue
    else
      parsed = parser.parse line
      
      top = parsed[2][0]
      bottom = parsed[2][1]

      result = {}
      resultNum = 1

      for fundamental in fundamentals
        result[fundamental] = 0

      for unit in top
        for referredFundamental, val of units[unit[0]].units
          result[referredFundamental] += val * unit[1]
        resultNum *= units[unit[0]].number ** unit[1]
      
      if bottom? then for unit in bottom
        for referredFundamental, val of units[unit[0]].units
          result[referredFundamental] -= val * unit[1]
        resultNum /= units[unit[0]].number ** unit[1]

      units[parsed[0]] = {
        name: parsed[0]
        number: Number(parsed[1]) * resultNum
        units: result
      }

  console.log JSON.stringify {
    fundamentals: fundamentals
    units: units
  }, null, 2
