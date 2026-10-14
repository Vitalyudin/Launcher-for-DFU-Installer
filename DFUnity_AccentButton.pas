unit DFUnity_AccentButton;

// Акцентная кнопка (заливка системным синим, белый текст, значок слева).
// Рисуется сама, а не темой Windows - чтобы выделяться на фоне обычных кнопок.

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms;

type
  TAccentButton = class(TGraphicControl)
  private
    FHover, FPressed: Boolean;
    FIcon: string;           // символ из IconFont, '' - без значка
    FIconFont: string;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure SetupIconFont;
    function IconWidth: Integer;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    // Ширина по содержимому, но не меньше MinWidth и не больше MaxWidth
    procedure FitWidth(MinWidth, MaxWidth: Integer);
    property Caption;
    property Font;
    property OnClick;
  end;

implementation

const
  Padding  = 14;   // поля слева и справа
  IconGap  = 8;    // между значком и текстом
  Radius   = 6;
  // Системный синий Windows 10 и его оттенки (TColor - это $BBGGRR)
  ColorNormal  = $00D77800;  // RGB(0, 120, 215)
  ColorHover   = $00E68A1A;  // RGB(26, 138, 230)
  ColorPressed = $00B4650A;  // RGB(10, 101, 180)
  ColorBorder  = $009E5A00;  // RGB(0, 90, 158)

constructor TAccentButton.Create(AOwner: TComponent);
begin
  inherited;
  // Не csOpaque: за скруглёнными углами должен быть виден фон формы
  ControlStyle := ControlStyle - [csDoubleClicks];
  Cursor := crHandPoint;
  Font.Name := 'Segoe UI';
  Font.Height := -13;
  Font.Style := [fsBold];
  Font.Color := clWhite;
  SetupIconFont;
end;

procedure TAccentButton.SetupIconFont;
begin
  // Значок «Загрузка» из системного шрифта Windows 10+, на Windows 7/8 - стрелка ↓ из Segoe UI
  if Screen.Fonts.IndexOf('Segoe MDL2 Assets') >= 0 then
  begin
    FIconFont := 'Segoe MDL2 Assets';
    FIcon := #$E896;
  end
  else
  begin
    FIconFont := 'Segoe UI';
    FIcon := #$2193;
  end;
end;

function TAccentButton.IconWidth: Integer;
begin
  Canvas.Font.Name := FIconFont;
  Canvas.Font.Height := -14;
  Canvas.Font.Style := [];
  Result := Canvas.TextWidth(FIcon);
end;

procedure TAccentButton.FitWidth(MinWidth, MaxWidth: Integer);
var
  W, IconW: Integer;
begin
  IconW := IconWidth;
  Canvas.Font := Font;
  W := Padding + IconW + IconGap + Canvas.TextWidth(Caption) + Padding;
  if W < MinWidth then
    W := MinWidth;
  if W > MaxWidth then
    W := MaxWidth;
  Width := W;
end;

procedure TAccentButton.Paint;
var
  R, TextR: TRect;
  IconW, TextW, ContentW, X: Integer;
begin
  R := ClientRect;
  if FPressed and FHover then
    Canvas.Brush.Color := ColorPressed
  else if FHover then
    Canvas.Brush.Color := ColorHover
  else
    Canvas.Brush.Color := ColorNormal;
  Canvas.Pen.Color := ColorBorder;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, Radius, Radius);

  IconW := IconWidth;
  Canvas.Font := Font;
  TextW := Canvas.TextWidth(Caption);
  ContentW := IconW + IconGap + TextW;
  // Если текст не влезает - прижимаем к левому полю и обрезаем многоточием
  if ContentW > Width - 2 * Padding then
    X := Padding
  else
    X := (Width - ContentW) div 2;

  Canvas.Brush.Style := bsClear;
  Canvas.Font.Name := FIconFont;
  Canvas.Font.Height := -14;
  Canvas.Font.Style := [];
  Canvas.Font.Color := Font.Color;
  TextR := Rect(X, R.Top, X + IconW, R.Bottom);
  DrawText(Canvas.Handle, PChar(FIcon), -1, TextR, DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX);

  Canvas.Font := Font;
  TextR := Rect(X + IconW + IconGap, R.Top, R.Right - Padding, R.Bottom);
  DrawText(Canvas.Handle, PChar(Caption), -1, TextR,
    DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
  Canvas.Brush.Style := bsSolid;
end;

procedure TAccentButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    FPressed := True;
    Invalidate;
  end;
end;

procedure TAccentButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FPressed then
  begin
    FPressed := False;
    Invalidate;
  end;
  inherited;
end;

procedure TAccentButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  FHover := True;
  Invalidate;
end;

procedure TAccentButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FHover := False;
  Invalidate;
end;

procedure TAccentButton.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

end.
