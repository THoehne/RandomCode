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

end.

