unit unmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus;

type

  TGrid = Array of Array of Boolean;
  TPoints = Array of TPoint;

  { TfrmMain }

  TfrmMain = class(TForm)
    btn_start: TButton;
    btn_stop: TButton;
    cbx_amount: TComboBox;
    ckb_show_solutions: TCheckBox;
    ckb_do_break_on_solution: TCheckBox;
    ckb_do_grapic_in: TCheckBox;
    edt_wait_time_in: TEdit;
    Label1: TLabel;
    mem_pos_out: TMemo;
    PNL_position_output: TPanel;
    pbx_board: TPaintBox;
    PNL_viewport: TPanel;
    PNL_head: TPanel;
    procedure btn_startClick(Sender: TObject);
    procedure btn_stopClick(Sender: TObject);
    procedure cbx_amountChange(Sender: TObject);
    procedure ckb_do_break_on_solutionChange(Sender: TObject);
    procedure ckb_do_grapic_inChange(Sender: TObject);
    procedure ckb_show_solutionsChange(Sender: TObject);
    procedure mem_pos_outMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PNL_headClick(Sender: TObject);

    function TestPosition(x,y,size: Integer): Boolean;
    function CheckHV(x,y:Integer): Boolean;
    function CheckDiagonal(x,y,size:Integer): Boolean;
    procedure RemoveQueen(x,y:Integer);
    procedure LockQueen(x,y,size: Integer);
    procedure UnlockQueen(x,y,size: Integer);
    procedure FoundSolution(size: Integer);
    procedure CreateQueenGrid(size: Integer);
    procedure InitChessBoard(size: Integer);
    procedure ReInitQueenGrid();
    procedure PlaceQueen(x, y: Integer);
    procedure SetTestedField(x, y: Integer);
    procedure ClearField(x, y: Integer);
    procedure Search(max_amount, current_queens, current_x: Integer);
    procedure StartSearch(amount: Integer);
  private
    queen_grid: TGrid;
    h_prefixes: Array of Byte;
    vr_prefixes: Array of Byte;
    v_prefixes: Array of Byte;
    field_size: TPoint;
    stop: Boolean;
    wait_time: Integer;
    do_graphics: Boolean;
    found_solutions: Integer;
    break_on_solution: Boolean;
    show_solutions: Boolean;
    is_running: Boolean;

    start_no_g_wait: DWord;
    no_g_process_wait: Integer;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure Wait(ms: Integer);
var
  tc : DWORD;
begin
  tc := GetTickCount64;
  while (GetTickCount64 < tc + ms) and (not Application.Terminated) do
    Application.ProcessMessages;
end;




function LeftCollidesWithYZero(x,y:Integer): Boolean;
begin
  if y <= x then Result := True
  else Result := False;
end;

function RightCollidesWithYZero(x,y,size:Integer): Boolean;
begin
  if y <= (size - x + 1) then Result := True
  else Result := False;
end;

function TfrmMain.CheckHV(x,y:Integer): Boolean;
// Returns true if fields are free and false if not.
var v_prefix: Byte;
  h_prefix: Byte;
begin
  Result := True;
  // Fields are counted from 1,2,3,...,n. Array is 0,1,2,...,n
  h_prefix := h_prefixes[x - 1];
  v_prefix := v_prefixes[y - 1];

  //if h_prefix > 3 then Result := False;
  //if v_prefix > 3 then Result := False;
  if h_prefix and 4 = 4 then Result := False;
  if v_prefix and 4 = 4 then Result := False;
end;

function TfrmMain.CheckDiagonal(x,y,size:Integer): Boolean;
// Returns false if fields are blocked and true if not.
var left_prefix: Byte;
  right_prefix: Byte;
begin
  if LeftCollidesWithYZero(x,y) then left_prefix := h_prefixes[x - y]
  else left_prefix := v_prefixes[y - x];

  if RightCollidesWithYZero(x,y,size) then right_prefix := h_prefixes[x + y - 2] // the swap between 0 1 2 ... and 1 2 3 ... causes the index to be 2 off. This of course doesn't matter with "-" only "+"
  else right_prefix := vr_prefixes[y - size + x - 1];

  Result := not (right_prefix and 1 = 1) and not (left_prefix and 2 = 2)
end;

function TfrmMain.TestPosition(x, y, size: Integer): Boolean;
begin
  Result := CheckHV(x,y) and CheckDiagonal(x,y,size);
end;





procedure TfrmMain.FoundSolution(size: Integer);
var points: String;
  i,j: Integer;
begin
  Inc(found_solutions);

  if not show_solutions then exit();

  points := IntToStr(found_solutions) + ':';

  for i := 0 to size - 1 do
  begin
    for j := 0 to size - 1 do
    begin
      if queen_grid[i,j] then points := points + ' ' + Chr(64+j+1) + IntToStr(i+1) + '';
    end;
  end;

  mem_pos_out.Lines.Add(points);
  if break_on_solution then
  begin
    if MessageDlg('Neue Lösung.', 'Neue Lösung gefunden.', mtInformation, [mbOK, mbIgnore], 0) = mrIgnore then
    begin
      break_on_solution := False;
      ckb_do_break_on_solution.Checked:=False;
    end;
  end;
end;

procedure TfrmMain.PlaceQueen(x,y: Integer);
begin
  pbx_board.Canvas.Pen.Style := psClear;
  pbx_board.Canvas.Brush.Color := clGreen;
  pbx_board.Canvas.Rectangle(field_size.X * (x-1) + 51,
                             field_size.Y * (y-1) + 51,
                             field_size.X + (field_size.X * (x-1) + 51),
                             field_size.Y + (field_size.Y * (y-1) + 51)
                             );

  pbx_board.Canvas.Brush.Color := clDefault;
  pbx_board.Canvas.Pen.Style := psSolid;
end;

procedure TfrmMain.RemoveQueen(x,y:Integer);
begin
  ClearField(x,y);
end;

procedure TfrmMain.SetTestedField(x,y: Integer);
begin
  pbx_board.Canvas.Pen.Style := psClear;
  pbx_board.Canvas.Brush.Color := clBlue;
  pbx_board.Canvas.Rectangle(field_size.X * (x-1) + 51,
                             field_size.Y * (y-1) + 51,
                             field_size.X + (field_size.X * (x-1) + 51),
                             field_size.Y + (field_size.Y * (y-1) + 51)
                             );

  pbx_board.Canvas.Brush.Color := clDefault;
  pbx_board.Canvas.Pen.Style := psSolid;
end;

procedure TfrmMain.ClearField(x,y: Integer);
begin
  pbx_board.Canvas.Pen.Style := psClear;
  pbx_board.Canvas.Rectangle(field_size.X * (x-1) + 51,
                             field_size.Y * (y-1) + 51,
                             field_size.X + (field_size.X * (x-1) + 51),
                             field_size.Y + (field_size.Y * (y-1) + 51)
                             );
  pbx_board.Canvas.Pen.Style := psSolid;
end;

procedure TfrmMain.LockQueen(x,y,size: Integer);
begin
  queen_grid[x - 1, y - 1] := True;

  h_prefixes[x - 1] := h_prefixes[x - 1] + 4;
  v_prefixes[y - 1] := v_prefixes[y - 1] + 4;

  if LeftCollidesWithYZero(x,y) then h_prefixes[x - y] := h_prefixes[x - y] + 2
  else v_prefixes[y - x] := v_prefixes[y - x] + 2;

  if RightCollidesWithYZero(x,y,size) then h_prefixes[x + y - 2] := h_prefixes[x + y - 2] + 1
  else vr_prefixes[y - size + x - 1] := vr_prefixes[y - size + x - 1] + 1;
end;

procedure TfrmMain.UnlockQueen(x,y,size: Integer);
begin
  queen_grid[x - 1, y - 1] := False;

  h_prefixes[x - 1] := h_prefixes[x - 1] - 4;
  v_prefixes[y - 1] := v_prefixes[y - 1] - 4;

  if LeftCollidesWithYZero(x,y) then h_prefixes[x - y] := h_prefixes[x - y] - 2
  else v_prefixes[y - x] := v_prefixes[y - x] - 2;

  if RightCollidesWithYZero(x,y,size) then h_prefixes[x + y - 2] := h_prefixes[x + y - 2] - 1
  else vr_prefixes[y - size + x - 1] := vr_prefixes[y - size + x - 1] - 1;
end;

procedure TfrmMain.Search(max_amount, current_queens, current_x: Integer);
var y: Integer;
begin
  if stop then exit();
  if max_amount = current_queens then
  begin
    FoundSolution(max_amount);
    exit();
  end;

  for y := 1 to max_amount do
  begin

    if do_graphics then
    begin
      SetTestedField(current_x, y);
      Wait(wait_time);
    end;

    if TestPosition(current_x,y,max_amount) then
    begin

      if do_graphics then
      begin
        PlaceQueen(current_x, y);
        Application.ProcessMessages;
        Wait(wait_time);
      end
      else
      begin
        // Allow window response.
        if (start_no_g_wait = 0) then
        begin
          start_no_g_wait := GetTickCount64;
        end
        else if (GetTickCount64 > start_no_g_wait + no_g_process_wait) then
        begin
          Application.ProcessMessages;
          start_no_g_wait := 0;
        end;
      end;

      // Start of recursive backtracking part
      LockQueen(current_x, y, max_amount);

      Search(max_amount, current_queens + 1, current_x + 1);

      UnlockQueen(current_x,y,max_amount);
      // End of recursive backtracking part

      //if do_graphics then ClearField(current_x, y);
      //
      //if stop then exit();
    end;

    if do_graphics then ClearField(current_x, y);
    if stop then exit();
  end;
end;

procedure TfrmMain.ReInitQueenGrid();
var i,j: Integer;
begin
    for i := 0 to Length(queen_grid) - 1 do
  begin
    for j := 0 to Length(queen_grid[i]) - 1 do
    begin
      queen_grid[i,j] := False;
    end;
  end;

  for i := 0 to Length(h_prefixes) - 1 do
  begin
    h_prefixes[i] := 0;
    v_prefixes[i] := 0;
    vr_prefixes[i] := 0;
  end;
end;

procedure TfrmMain.StartSearch(amount: Integer);
begin
  is_running := True;
  Search(amount, 0, 1);
  stop := False;
  is_running := False;

  // Print last line (amount of solutions)
  mem_pos_out.Lines.Add('');
  mem_pos_out.Lines.Add('Solutions found: ' + IntToStr(found_solutions));

  ReInitQueenGrid();
end;

procedure TfrmMain.CreateQueenGrid(size: Integer);
begin
  SetLength(queen_grid, size, size);

  SetLength(h_prefixes, size);
  SetLength(v_prefixes, size);
  SetLength(vr_prefixes, size);
end;

procedure TfrmMain.InitChessBoard(size: Integer);
var board_size: TRect;
  i: Integer;
  half_number_size: Integer;
begin;
  pbx_board.Canvas.Pen.Width := 1;
  pbx_board.Canvas.Brush.Style := bsSolid;
  pbx_board.Canvas.Clear;

  board_size := TRect.Create(0,0,pbx_board.Width, pbx_board.Height);

  pbx_board.Canvas.Brush.Style := bsClear;

  field_size := TPoint.Create(Round((board_size.Width - 100) / size), Round((board_size.Height - 100) / size)); // trunc causes much more deviation
  pbx_board.Canvas.Rectangle(50,50, field_size.X * size + 51, field_size.Y * size + 51);

  // paint vertical lines
  for i := 1 to size - 1 do
  begin
    half_number_size := pbx_board.Canvas.TextWidth(IntToStr(i)) div 2;
    pbx_board.Canvas.TextOut(field_size.X * i + 50 - (field_size.X div 2) - half_number_size, 25, IntToStr(i));
    pbx_board.Canvas.Line(field_size.X * i + 50, 50, field_size.X * i + 50, field_size.Y * size + 50);
  end;
  half_number_size := pbx_board.Canvas.TextWidth(IntToStr(i)) div 2;
  pbx_board.Canvas.TextOut(field_size.X * size + 50 - (field_size.X div 2) - half_number_size, 25, IntToStr(size));

  // paint horizontal lines
  for i := 1 to size - 1 do
  begin
    half_number_size := pbx_board.Canvas.TextHeight(IntToStr(i)) div 2;
    pbx_board.Canvas.TextOut(25, field_size.Y * i + 50 - (field_size.Y div 2) - half_number_size, Chr(64 + i));
    pbx_board.Canvas.Line(50, field_size.Y * i + 50, field_size.X * size + 50, field_size.Y * i + 50);
  end;
  half_number_size := pbx_board.Canvas.TextHeight(IntToStr(i)) div 2;
  pbx_board.Canvas.TextOut(25, field_size.Y * size + 50 - (field_size.Y div 2) - half_number_size, Chr(64 + size));

  pbx_board.Canvas.Brush.Style := bsSolid;
end;

procedure TfrmMain.btn_startClick(Sender: TObject);
var amount: Integer;
begin
  try
    amount := StrToInt(cbx_amount.Items[cbx_amount.ItemIndex]);
  except
    ShowMessage('Bitte einen Wert auswählen.');
    exit();
  end;
  try
    wait_time := StrToInt(edt_wait_time_in.Text);
  except
    ShowMessage('Wartezeit muss eine Zahl sein');
    exit();
  end;

  if wait_time < 0 then
  begin
    ShowMessage('Wartezeit muss größer oder gleich 0 sein.');
    exit();
  end;

  found_solutions := 0;
  mem_pos_out.Clear;

  CreateQueenGrid(amount);

  stop := False;

  StartSearch(amount);
end;

procedure TfrmMain.btn_stopClick(Sender: TObject);
begin
  stop := true;
end;

procedure TfrmMain.cbx_amountChange(Sender: TObject);
begin
  stop := True;
  Wait(wait_time);
  InitChessBoard(StrToInt(cbx_amount.Items[cbx_amount.ItemIndex]));
  stop := False;
  no_g_process_wait:=1000;
end;

procedure TfrmMain.ckb_do_break_on_solutionChange(Sender: TObject);
begin
  break_on_solution := ckb_do_break_on_solution.Checked;
end;

procedure TfrmMain.ckb_do_grapic_inChange(Sender: TObject);
begin
  do_graphics := ckb_do_grapic_in.Checked;
end;

procedure TfrmMain.ckb_show_solutionsChange(Sender: TObject);
begin
  show_solutions := ckb_show_solutions.Checked;
end;

procedure ParseLine(line: String; var points:TPoints);
var s_points: TStringArray;
    i: Integer;
    s_point: String;
    point: TPoint;
    x,y: Integer;
begin
  s_points := line.Split(' ');
  SetLength(points, Length(s_points) - 1);

  for i:= 1 to Length(s_points) - 1 do
  begin
    s_point := s_points[i];

    y := Ord(s_point.Chars[0]) - 64;
    s_point := s_point.Remove(0,1);

    x := StrToInt(s_point);

    point := TPoint.Create(x,y);
    points[i - 1] := point;
  end;
end;

procedure TfrmMain.mem_pos_outMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var line_index: Integer;
    points: TPoints;
    i: Integer;
begin
  if is_running then exit();
  line_index := mem_pos_out.CaretPos.Y;

  try
    ParseLine(mem_pos_out.Lines.ValueFromIndex[line_index], points);
  except
    exit();
  end;


  InitChessBoard(Length(points));

  for i := 0 to Length(points) - 1 do
  begin
    PlaceQueen(points[i].x, points[i].y);
  end;
end;

procedure TfrmMain.PNL_headClick(Sender: TObject);
begin
  do_graphics := False;
  break_on_solution := False;
  show_solutions := False;
end;

end.

