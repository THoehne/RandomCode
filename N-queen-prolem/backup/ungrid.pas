unit ungrid;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs;

type

  { TfrmGrid }

  TGrid = Array of Array of Boolean;

  TfrmGrid = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    queen_grid: TGrid;
    h_prefixes: TBytes;
    vr_prefixes: TBytes;
    v_prefixes: TBytes;
  public

  end;

var
  frmGrid: TfrmGrid;

implementation

{$R *.lfm}

{ TfrmGrid }

procedure TfrmGrid.FormCreate(Sender: TObject);
begin

end;

procedure TfrmGrid.Define(_queen_grid: TGrid; _h_prefixes, _v_prefixes, _vr_prefixes: TBytes);
begin

end;

end.

