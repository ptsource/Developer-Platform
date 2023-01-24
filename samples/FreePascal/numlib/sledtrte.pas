program sledtrte;

uses
  typ,
  iom,
  sle;

const
  m1 = -10;
  m2 = 10;

type
  array1dr = array[m1..m2] of ArbFloat;

var
  k, nex, ex, i, n, term: ArbInt;
  l, d, u, b, x: array1dr;

begin
  Write('program results sledtrte ');
  case SizeOf(ArbFloat) of
    4: writeln('(single)');
    8: writeln('(double)');
    6: writeln('(real)');
  end;
  Read(nex);
  writeln;
  writeln('  number of examples : ', nex: 2);
  for ex := 1 to nex do
  begin
    writeln;
    writeln(' example number :', ex: 2);
    writeln;
    Read(n, k);
    iomrev(input, l[k + 1], n - 1);
    iomrev(input, d[k], n);
    iomrev(input, u[k], n - 1);
    iomrev(input, b[k], n);
    sledtr(n, l[k + 1], d[k], u[k], b[k], x[k], term);
    writeln;
    writeln(' A =');
    for i := 1 to n do
    begin
      if i > 1 then
        Write('': (i - 2) * (numdig + 2), l[k + i - 1]: numdig, '': 2);
      Write(d[k + i - 1]: numdig, '': 2);
      if i < n then
        Write(u[k + i - 1]: numdig);
      writeln;
    end;
    writeln;
    writeln(' b =');
    iomwrv(output, b[k], n, numdig);
    writeln;
    writeln('term=', term: 2);
    case term of
      1:
      begin
        writeln('x=');
        iomwrv(output, x[k], n, numdig);
      end;
      2: writeln('solution not possible');
      3: writeln(' wrong value of n');
    end;
    writeln('-----------------------------------------------');
  end; {example}
  Close(input);
  Close(output);
end.
