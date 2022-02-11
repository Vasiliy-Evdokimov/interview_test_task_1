program blit;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils;

var
  TransformArray: array [0..15] of string =
    ('0000', '1000', '0001', '0010',
     '0000', '0010', '1011', '1011',
     '0100', '0101', '0111', '1111',
     '1101', '1110', '0111', '1111');

type
  TPyramidCell = class(TObject)
    index: byte;
    row: byte;
    col: byte;
    //
    digit: byte;
  end;

  TPyramid = class(TObject)
    FCells: array of TPyramidCell;
    //
    procedure FillFromBin(aBin: string); virtual; abstract;
    procedure Transform(); virtual; abstract;
    function CanBeReduced(): boolean; virtual; abstract;
    function GetBin(): string;
    function GetSum(): integer;
    procedure ClearCells(); virtual;
    procedure Print(aPrefix: string = '');
  end;

  TFourCellPyramid = class(TPyramid)
    index: integer;
    row: integer;
    col: integer;
    //
    procedure FillFromBin(aBin: string); override;
    procedure Transform(); override;
    function CanBeReduced(): boolean; override;
    //
    function GetReduced(): integer;
    //
    constructor Create();
  end;

  TMainPyramid = class(TPyramid)
  private
    FFourCells: array of TFourCellPyramid;
  public
    procedure FillFromBin(aBin: string); override;
    procedure Transform(); override;
    function CanBeReduced(): boolean; override;
    //
    function Reduce(): boolean;
    procedure PrintRowByRow();
    procedure ClearCells(); override;
    //
    constructor Create(aInput: string);
    destructor Destroy(); override;
  end;

  function BinToDec(aBin: string): integer;
  var i: integer;
  begin
    Result := 0;
    for i := 1 to length(aBin) do
    begin
      Result := Result shl 1;
      if aBin[i] = '1' then
        Result := Result or 1;
    end;
  end;

{ TMainPyramid }

function TMainPyramid.CanBeReduced: boolean;
var i: integer;
begin
  Result := true;
  for i := 0 to length(FFourCells) - 1 do
    Result := Result and FFourCells[i].CanBeReduced();
end;

procedure TMainPyramid.ClearCells;
var i: integer;
begin
  inherited;
  //
  for i := 0 to length(FFourCells) - 1 do
    if Assigned(FFourCells[i]) then
      FFourCells[i].Free;
  SetLength(FFourCells, 0);
end;

constructor TMainPyramid.Create(aInput: string);
begin
  FillFromBin(aInput);
end;

destructor TMainPyramid.Destroy;
var i: integer;
begin
  ClearCells();
  //
  for i := 0 to length(FFourCells) - 1 do
    FFourCells[i].Free;
  //
  inherited;
end;

procedure TMainPyramid.FillFromBin(aBin: string);
var
  i, j, k,
  row_cells, cell4_idx, row_step: integer;
  Cell: TPyramidCell;
  Cell4: TFourCellPyramid;
  fl: boolean;
begin
  ClearCells();
  //
  SetLength(FCells, length(aBin));
  SetLength(FFourCells, length(FCells) div 4);
  //
  j := 0;
  row_cells := 1;
  k := -1;
  for i := 0 to length(FFourCells) - 1 do
  begin
    Cell4 := TFourCellPyramid.Create();
    Cell4.index := j;
    //
    if (k + 2) > row_cells then
    begin
      row_cells := row_cells + 2;
      k := -1;
    end;
    inc(k);
    //
    Cell4.row := row_cells div 2;
    Cell4.col := k;
    //
    FFourCells[j] := Cell4;
    //
    inc(j);
  end;
  //
  j := 0;
  row_cells := 1;
  k := -1;
  for i := length(aBin) downto 1 do
  begin
    Cell := TPyramidCell.Create();
    Cell.digit := strtoint(aBin[i]);
    Cell.index := j;
    //
    if (k + 2) > row_cells then
    begin
      row_cells := row_cells + 2;
      k := -1;
    end;
    inc(k);
    //
    Cell.row := row_cells div 2;
    Cell.col := k;
    //
    FCells[j] := Cell;
    //
    inc(j);
  end;
  //
  fl := false;
  cell4_idx := -1;
  if length(FFourCells) > 0 then
    for i := 0 to length(FCells) - 1 do
    begin
      Cell := FCells[i];
      if (Cell.row mod 2 <> 0) then continue;
      //
      row_step := (Cell.row div 2) * 4 + 2;
      if (Cell.col mod 4 = 0) then
      begin
        // vertex of regular four cells pyramid
        inc(cell4_idx);
        FFourCells[cell4_idx].FCells[0] := Cell;
        FFourCells[cell4_idx].FCells[1] := FCells[Cell.index + row_step - 1];
        FFourCells[cell4_idx].FCells[2] := FCells[Cell.index + row_step - 0];
        FFourCells[cell4_idx].FCells[3] := FCells[Cell.index + row_step + 1];
        //
        fl := true;
      end else
      begin
        // vertex of inverted four cells pyramid
        if fl then
        begin
          fl := false;
          inc(cell4_idx);
          FFourCells[cell4_idx].FCells[0] := FCells[Cell.index + 1 + row_step];
          FFourCells[cell4_idx].FCells[1] := Cell;
          FFourCells[cell4_idx].FCells[2] := FCells[Cell.index + 1];
          FFourCells[cell4_idx].FCells[3] := FCells[Cell.index + 2];
        end;
      end;
    end;
end;

procedure TMainPyramid.PrintRowByRow;
var
  i, j: integer;
  s: string;
begin
  Writeln('PyramidRowByRow = ');
  s := '';
  j := -1;
  for i := 0 to length(FCells) - 1 do
  begin
    if FCells[i].row <> j then
    begin
      if s <> '' then Writeln(s);
      j := FCells[i].row;
      s := '';
    end;
    s := s + inttostr(FCells[i].digit);
  end;
  if s <> '' then Writeln(s);
  //
  Writeln('PyramidFourCells = ');
  for i := 0 to length(FFourCells) - 1 do
    Writeln(FFourCells[i].GetBin());
end;

function TMainPyramid.Reduce(): boolean;
var
  i: integer;
  s: string;
begin
  Result := false;
  //
  if not CanBeReduced() then exit;
  //
  s := '';
  for i := 0 to Length(FFourCells) - 1 do
    s := inttostr(FFourCells[i].GetReduced()) + s;
  FillFromBin(s);
  //
  Result := true;
end;

procedure TMainPyramid.Transform;
var i: integer;
begin
  for i := 0 to length(FFourCells) - 1 do
    FFourCells[i].Transform();
end;

var
  i, j: integer;
  s: string;
  fl, fl2: boolean;
  Pyramid: TMainPyramid;

{ TFourCellPyramid }

function TFourCellPyramid.CanBeReduced(): boolean;
begin
  Result := ((GetSum() mod 4) = 0);
end;

constructor TFourCellPyramid.Create;
begin
  SetLength(FCells, 4);
end;

procedure TFourCellPyramid.FillFromBin(aBin: string);
var i: integer;
begin
  if length(aBin) <> 4 then exit;
  //
  for i := 0 to 3 do
    FCells[i].digit := strtoint(aBin[4 - i]);
end;

function TFourCellPyramid.GetReduced: integer;
begin
  Result := GetSum() div 4;
end;

procedure TFourCellPyramid.Transform;
var i: integer;
begin
  i := BinToDec(GetBin());
  FillFromBin(TransformArray[i]);
end;

{ TPyramid }

procedure TPyramid.ClearCells;
var i: integer;
begin
  for i := 0 to length(FCells) - 1 do
    if Assigned(FCells[i]) then
      FCells[i].Free;
  SetLength(FCells, 0);
end;

function TPyramid.GetBin: string;
var i: integer;
begin
  Result := '';
  for i := 0 to Length(FCells) - 1 do
    Result := inttostr(FCells[i].digit) + Result;
end;

function TPyramid.GetSum: integer;
var i: integer;
begin
  Result := 0;
  for i := 0 to Length(FCells) - 1 do
    Result := Result + FCells[i].digit;
end;

procedure TPyramid.Print(aPrefix: string = '');
begin
  if aPrefix <> '' then Writeln(aPrefix);
  Writeln(GetBin());
end;

begin
  try
    // check parameter exists
    if ParamCount < 1 then
    begin
      WriteLn('No parameters specified!');
      //ReadLn;
      exit;
    end;
    // check correct binary
    s := trim(ParamStr(1));
    fl := true;
    for i := 1 to length(s) do
      if (s[i] <> '0') and (s[i] <> '1') then
      begin
        fl := false;
        break;
      end;
    // check cells amount is power of four
    j := length(s);
    fl2 := true;
    while (j <> 1) do
    begin
      if (j mod 4 <> 0) then
      begin
        fl2 := false;
        break
      end;
      j := j div 4;
    end;
    fl := fl and fl2;
    //
    if (s = '') or (not fl) then
    begin
      WriteLn('Incorrect parameter!');
      //ReadLn;
      exit;
    end;
    //
    Pyramid := TMainPyramid.Create(s);
    try
      Pyramid.Print();
      //Pyramid.PrintRowByRow();
      //
      while length(Pyramid.FCells) > 1 do
      begin
        Pyramid.Transform();
        Pyramid.Print({'After transform = '});
        //Pyramid.PrintRowByRow();
        if Pyramid.Reduce()
          then Pyramid.Print({'After reduce = '});
        //Pyramid.PrintRowByRow();
      end;
    finally
      Pyramid.Free;
    end;
    //
    //WriteLn('Done!');
    //ReadLn;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;
end.
