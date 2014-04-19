require ['./web'], (executor) ->
  input = ace.edit 'input'
  output = $ '#output'

  iomatch = false

  stipulate = (text) ->
    ctx = new executor.ExecutionContext ['g', 'L', 'kJ', 'mol', 'A', 'K']

    lines = text.split '\n'
    resultLines = []

    for line in lines
      if line[0..1] is '  '
        resultLines.push '$$' + ctx.execute(line.trimLeft()).replace(/_/g, '\\_') + '$$'
      else
        resultLines.push line

    return resultLines.join '\n'

  reparse = ->
    if iomatch
      setTimeout reparse, 1000
    else
      try
        oldScrollTop = output.scrollTop()
        output.html marked stipulate input.getValue()
        MathJax.Hub.Queue ['Typeset', MathJax.Hub, 'output']
        MathJax.Hub.Queue ->
          output.scrollTop oldScrollTop
          setTimeout reparse, 1000
      catch e
        console.log e.stack
        setTimeout reparse, 1000

      iomatch = true

  reparse()

  input.on 'change', ->
    iomatch = false
