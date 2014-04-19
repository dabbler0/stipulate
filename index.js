(function() {
  require(['./web'], function(executor) {
    var input, iomatch, output, reparse, stipulate;
    input = ace.edit('input');
    output = $('#output');
    iomatch = false;
    stipulate = function(text) {
      var ctx, line, lines, resultLines, _i, _len;
      ctx = new executor.ExecutionContext(['g', 'L', 'kJ', 'mol', 'A', 'K']);
      lines = text.split('\n');
      resultLines = [];
      for (_i = 0, _len = lines.length; _i < _len; _i++) {
        line = lines[_i];
        if (line.slice(0, 2) === '  ') {
          resultLines.push('$$' + ctx.execute(line.trimLeft()).replace(/_/g, '\\_') + '$$');
        } else {
          resultLines.push(line);
        }
      }
      return resultLines.join('\n');
    };
    reparse = function() {
      var e, oldScrollTop;
      if (iomatch) {
        return setTimeout(reparse, 1000);
      } else {
        try {
          oldScrollTop = output.scrollTop();
          output.html(marked(stipulate(input.getValue())));
          MathJax.Hub.Queue(['Typeset', MathJax.Hub, 'output']);
          MathJax.Hub.Queue(function() {
            output.scrollTop(oldScrollTop);
            return setTimeout(reparse, 1000);
          });
        } catch (_error) {
          e = _error;
          console.log(e.stack);
          setTimeout(reparse, 1000);
        }
        return iomatch = true;
      }
    };
    reparse();
    return input.on('change', function() {
      return iomatch = false;
    });
  });

}).call(this);

//# sourceMappingURL=index.js.map
