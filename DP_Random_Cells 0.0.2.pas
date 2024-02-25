{
  Рандомный залипательный клеточный автомат
  Esc - clear
  Space - edit/view
  R - randomize
  Arrows - tile size
  Mouse - edit tile
  + - inc pixel size
  - - dec pixel size
  C - chaotic
  Q - random rules
  1,2 - +- Num
  3,4 - +- Num1
  5,6 - +- Num2
  7,8 - +- Rule
}
Uses GraphABC, System.Drawing, System.Drawing.Imaging;

var
  TW := 32;
  TH := 32;
  PS := 10; // Pixel size
  W := TW * PS;
  H := TH * PS;
  /// Массив пикселей которым заполняется Bmp.
  RawBmp := new Byte[W * H * 4];
  MaketBmp := new Byte[TW * TH * 4];
  Bmp: Bitmap;
  Tile: array[,] of Color;
  Buffer: array[,] of Color;
  ForDetectChanges: array[,] of Color;
  Scale: integer := 4;
  ShowMaket: boolean;
  ShowNumbers: boolean := true;
  Run: boolean := true;
  CycleUpdoot: integer;
  Num, Num1, Num2: integer; //Сколько соседей у клетки дожно быть по кресту и по диагонали
  Rule: integer; //Правило обработки клеток
  KeyCode: integer := -11000;
  KeyPressed: boolean;
  MouseX, MouseY: integer;
  MousePressed: boolean;
  MouseCode: integer;
  Resized: boolean;
  Changed: boolean;
  WheelColor := clRed;

function BytesToImage(bytes: array of byte; Width: integer): Bitmap;
begin
  var Height := (bytes.Length div 4) div Width;
  result := new Bitmap(Width, Height);
  var rect := new Rectangle(0, 0, Width, Height);
  var bmData := result.LockBits(rect, ImageLockMode.WriteOnly, result.PixelFormat);
  System.Runtime.InteropServices.Marshal.Copy(bytes, 0, bmData.Scan0, bytes.Length);
  result.UnlockBits(bmData);
end;

procedure KeyDown(key: integer);
begin
  KeyCode := key;
  KeyPressed := true;
end;

procedure KeyUp(key: integer);
begin
  KeyCode := -11000;
  KeyPressed := false;
end;

procedure MouseDown(x, y, mb: integer);
begin
  MouseX := x;
  MouseY := y;
  MousePressed := true;
  MouseCode := mb;
end;

procedure MouseMove(x, y, mb: integer);
begin
  MouseX := x;
  MouseY := y;
  MouseCode := mb;
end;

procedure MouseUp(x, y, mb: integer);
begin
  MousePressed := false;
end;

procedure Init;
var
  Spawned: integer;
  Sx, Sy: integer;
begin
  SetLength(Tile, TW, TH);
  SetLength(ForDetectChanges, TW, TH);
  for i: integer := 0 to TH - 1 do
    for j: integer := 0 to TW - 1 do
      Tile[j, i] := clBlack;
  while Spawned < TW * TH / 2 do
  begin
    Sx := Random(0, TW - 1);
    Sy := Random(0, TH - 1);
    if Tile[Sx, Sy] <> clGreen then
    begin
      Spawned += 1;
      Tile[Sx, Sy] := clGreen;
    end;
  end;
end;

procedure DrawTile(var Bytes: array of byte; Width: integer);
begin
  var i, tx, ty: integer;
  // В цикле проходим по каждому пикселю.
  for var x := 0 to Width - 1 do
    for var y := 0 to Bytes.Length div (Width * 4) - 1 do
    begin
      i := (y * Width + x) * 4;
      tx := (x div Scale) mod TW;
      ty := (y div Scale) mod TH;
      bytes[i + 0] :=  Tile[tx, ty].B;
      bytes[i + 1] :=  Tile[tx, ty].G;
      bytes[i + 2] :=  Tile[tx, ty].R;
      bytes[i + 3] :=  255;
    end;
end;

procedure DrawMaket(var bytes1: array of byte);
begin
  var i: integer;
  // В цикле проходим по каждому пикселю.
  for var x := 0 to TW - 1 do
    for var y := 0 to TH - 1 do
    begin
      i := (y * TW + x) * 4;
      
      bytes1[i + 0] := Tile[x, y].B;
      bytes1[i + 1] := Tile[x, y].G;
      bytes1[i + 2] := Tile[x, y].R;
      bytes1[i + 3] := 255;
    end;
end;

procedure Show;
var
  Cx, Cy: integer; //Correct X and Y for show mouse coordinates info
begin
  if not ShowMaket then
  begin
    DrawTile(RawBmp, W);
    Bmp := BytesToImage(RawBmp, W);
    GraphBufferGraphics.Clear(color.Red);
    GraphBufferGraphics.DrawImage(Bmp, 0, 0);
  end
  else
  begin
    for i: integer := 0 to TH - 1 do //В данном случает так быстрее, можно раскомментировать три строки и увидеть более быстрый вариант, но такое не всем понравится
      for j: integer := 0 to TW - 1 do
      begin
        GraphABC.Brush.Color := Tile[j, i];
        FillRect(W div TW * j, H div TH * i, W div TW * (j + 1), H div TH * (i + 1));
      end;
    //DrawMaket(MaketBmp);
    //Bmp:= BytesToImage(MaketBmp,TW);
    //GraphBufferGraphics.DrawImage(Bmp,0,0,W,H);
    
    //Mouse
    if (MouseX < W - 1) and (MouseX > 1) and (MouseY < H - 1) and (MouseY > 1) then
    begin
      GraphABC.Brush.Color := ARGB(192, 100, 100, 100);
      Cx := 0;
      Cy := 0;
      if MouseX + 160 > W then
        Cx := -160;
      if MouseY + 170 > H then
        Cy := -170;
      FillRect(MouseX + 40 + Cx, MouseY + 70 + Cy, MouseX + 110 + Cx, MouseY + 120 + Cy);
      DrawTextCentered(MouseX + 20 + Cx, MouseY + 70 + Cy, MouseX + 130 + Cx, MouseY + 120 + Cy, IntToStr(Round((MouseX - (W / TW) / 2) / (W / TW)) + 1) + ' , ' + IntToStr(Round((MouseY - (H / TH) / 2) / (H / TH)) + 1));
      GraphABC.Brush.Color := ARGB(128, 255, 255, 255);
      Cx := Round((MouseX - (W / TW) / 2) / (W / TW));
      Cy := Round((MouseY - (H / TH) / 2) / (H / TH));
      FillRect(Round(W / TW * (Cx - 1)), Round(H / TH * (Cy - 1)), Round(W / TW * (Cx + 2)), Round(H / TH * (Cy + 2)));
      GRaphABC.Brush.Color := ARGB(128, 0, 0, 0);
      FillRect(Round(W / TW * Cx), Round(H / TH * Cy), Round(W / TW * (Cx + 1)), Round(H / TH * (Cy + 1)));
    end;
  end;
  //Rule
  if ShowNumbers then
  begin
    GraphABC.Brush.Color := ARGB(128, 100, 100, 100);
    GraphABC.Font.Color := ARGB(128, 255, 255, 255);
    TextOut(0, H - 20, Num + ', ' + Num1 + ', ' + Num2 + ', ' + Rule + ', ' + Changed.ToString.ToLower);
  end;
  Redraw;
end;

procedure StartScreen;
begin
  ClearWindow(clBlack);
  DrawTextCentered(0, 0, W, H,
    'Esc - очистить тайл' + newline +
    'Пробел - редактирование/просмотр' + newline +
    'Стрелки - размер тайла; Мышь - редактирование' + newline +
    'C(анг.) - запуск алгоритма; Q - случайные правила' + newline +
    'H(анг.) - показать/скрыть информацию' + newline +
    'R - случайный набор значений' + newline +
    '1,2 : -/+ Num0' + newline +
    '3,4 : -/+ Num1' + newline +
    '5,6 : -/+ Num2' + newline +
    '7,8 : -/+ Rule' + newline +
    '-,+ : -/+ масштаб' + newline +
    'M - этот экран' + newline +
    'За оптимизацию спасибо Александру Михайленко! (W)' + newline +
    'Нажмите любую кнопку...');
  Redraw;
  while KeyPressed do;
  while not KeyPressed do;
  
  ClearWindow(clBlack);
  DrawTextCentered(0, 0, W, H,
    'На одном окне стандартного размера всё не уместилось' + newline +
    'P - выбрать цвет для вставки колесиком' + newline +
    'Краткое объяснение алгоритма :' + newline +
    'Rule - правило обработки двух соседних ячеек' + newline +
    'Num0 - сумма черных ячеек вокруг клетки,' + newline +
    '8 позиций' + newline +
    'Num1, Num2 - сумма черных ячеек вокруг клетки' + newline +
    'по горизонтали и по вертикали соответственно' + newline +
    'Если Rule < 4 То используется Num0' + newline +
    'Иначе, используются Num1 и Num2' + newline +
    'в различных комбинациях правил' + newline +
    'Нажмите любую кнопку...');
  Redraw;
  while KeyPressed do;
  while not KeyPressed do;
end;

procedure _SetColor;
var
  DA1, DR1, DG1, DB1: integer;
  procedure Задать_цвет;
  var
    CA, CR, CG, CB: integer;
    procedure Интерфейс;
    begin
      LockDrawing;
      GraphABC.Brush.Color := clGray;
      FillRect(0, 0, W, H);
      GraphABC.Brush.Color := RGB(100, 100, 100);
      FillRoundRect(10, 10, W - 10, 30, 5, 5);
      GraphABC.Brush.Color := RGB(150, 100, 100);
      FillRoundRect(10, 40, W - 10, 60, 5, 5);
      GraphABC.Brush.Color := RGB(100, 150, 100);
      FillRoundRect(10, 70, W - 10, 90, 5, 5);
      GraphABC.Brush.Color := RGB(100, 100, 150);
      FillRoundRect(10, 100, W - 10, 120, 5, 5);
      GraphABC.Brush.Color := RGB(200, 200, 200);
      FillRoundRect(10 + Round((W - 40) / 255 * CA), 8, 10 + Round((W - 40) / 255 * CA) + 20, 32, 5, 5);
      FillRoundRect(10 + Round((W - 40) / 255 * CR), 38, 10 + Round((W - 40) / 255 * CR) + 20, 62, 5, 5);
      FillRoundRect(10 + Round((W - 40) / 255 * CG), 68, 10 + Round((W - 40) / 255 * CG) + 20, 92, 5, 5);
      FillRoundRect(10 + Round((W - 40) / 255 * CB), 98, 10 + Round((W - 40) / 255 * CB) + 20, 122, 5, 5);
      GraphABC.Brush.Color := ARGB(175, 150, 150, 150);
      TextOut(Round(W / 2), 10, IntToStr(CA));
      TextOut(Round(W / 2), 40, IntToStr(CR));
      TextOut(Round(W / 2), 70, IntToStr(CG));
      TextOut(Round(W / 2), 100, IntToStr(CB));
      
      GraphABC.Brush.Color := ARGB(CA, CR, CG, CB);
      FillRoundRect(10, 130, W - 10, H - 40, 5, 5);
      
      GraphABC.Brush.Color := clGray;
      DrawTextCentered(10, H - 30, W - 10, H, 'Нажмите Enter чтобы применить цвет, BackSpace чтобы завершить настройку цвета');
      Redraw;
      UnlockDrawing;
    end;
    
    procedure Управление;
    begin
      if KeyPressed then if KeyCode = 13 then
        begin
          DA1 := CA;
          DR1 := CR;
          DG1 := CG;
          DB1 := CB;
        end;
      if MousePressed then
      begin
        case MouseY of
          10..30:
            begin
              CA := Round((MouseX - 10) / ((W - 20) / 255));
              if MouseX < 10 then CA := 0;
              if MouseX > W - 10 then CA := 255;
            end;
          40..60:
            begin
              CR := Round((MouseX - 10) / ((W - 20) / 255));
              if MouseX < 10 then CR := 0;
              if MouseX > W - 10 then CR := 255;
            end;
          70..90:
            begin
              CG := Round((MouseX - 10) / ((W - 20) / 255));
              if MouseX < 10 then CG := 0;
              if MouseX > W - 10 then CG := 255;
            end;
          100..120:
            begin
              CB := Round((MouseX - 10) / ((W - 20) / 255));
              if MouseX < 10 then CB := 0;
              if MouseX > W - 10 then CB := 255;
            end;
        end;
      end;
    end;
  
  begin
    CA := 255;
    while KeyCode <> 8 do
    begin
      Интерфейс;
      Управление;
    end;
  end;

begin
  Задать_Цвет;
  WheelColor := ARGB(DA1, DR1, DG1, DB1);
end;

procedure Control;
begin
  if not Changed then begin Show; Redraw; while not KeyPressed and not MousePressed do Sleep(64) end; //Простой процессора тоже полезен
  if MousePressed then
    if MouseX < W then
      if MouseX > 0 then
        if MouseY < H then
          if MouseY > 0 then
            if ShowMaket then
              if MouseCode = 0 then
                Tile[Round((MouseX - (W / TW) / 2) / (W / TW)), Round((MouseY - (H / TH) / 2) / (H / TH))] := WheelColor
              else
              if MouseCode = 2 then
                Tile[Round((MouseX - (W / TW) / 2) / (W / TW)), Round((MouseY - (H / TH) / 2) / (H / TH))] := clGreen
              else
                Tile[Round((MouseX - (W / TW) / 2) / (W / TW)), Round((MouseY - (H / TH) / 2) / (H / TH))] := clBlack;
  if KeyPressed then
  begin
    if KeyCode = VK_Space then
      if ShowMaket then
        ShowMaket := false
      else
        ShowMaket := true;
    if KeyCode = VK_Right then
      if TW < 128 then
        TW += 1;
    if KeyCode = VK_Left then
      if TW > 4 then
        TW -= 1;
    if KeyCode = VK_Down then
      if TH < 128 then
        TH += 1;
    if KeyCode = VK_Up then
      if TH > 4 then
        TH -= 1;
    if KeyCode = VK_Escape then
      for i: integer := 0 to TH - 1 do
        for j: integer := 0 to TW - 1 do
          Tile[j, i] := clGreen;
    if KeyCode = VK_R then
      Init;
    if KeyCode = 187 then
      if Scale < 64 then
        Scale += 1;
    if KeyCode = 189 then
      if Scale > 1 then
        Scale -= 1;
    if KeyCode = VK_C then
      if Run then
        Run := false
      else
        Run := true;
    if KeyCode = VK_M then
      StartScreen;
    if KeyCode = VK_Q then
    begin
      Num := Random(9);
      Num1 := Random(5);
      Num2 := Random(5);
      Rule := Random(40);
    end;
    if KeyCode = 49 then
      if Num > 0 then Num -= 1;
    if KeyCode = 50 then
      if Num < 8 then Num += 1;
    if KeyCode = 51 then
      if Num1 > 0 then Num1 -= 1;
    if KeyCode = 52 then
      if Num1 < 4 then Num1 += 1;
    if KeyCode = 53 then
      if Num2 > 0 then Num2 -= 1;
    if KeyCode = 54 then
      if Num2 < 4 then Num2 += 1;
    if KeyCode = 55 then
      if Rule > 0 then Rule -= 1;
    if KeyCode = 56 then
      if Rule < 39 then Rule += 1;
    if KeyCode = VK_H then
      if ShowNumbers then
        ShowNumbers := false
      else
        ShowNumbers := true;
    if KeyCode = VK_P then
    begin
      _SetColor;
    end;
    if KeyCode = VK_W then System.Diagnostics.Process.Start('https://vk.com/id204027497');
    SetLength(Tile, TW, TH);
    SetLength(ForDetectChanges, TW, TH);
    while KeyPressed do;
  end;
end;

function CycX(x: integer): integer;
begin
  Result := x;
  if x > TW - 1 then
    Result := 0;
  if x < 0 then
    Result := TW - 1;
end;

function CycY(y: integer): integer;
begin
  Result := y;
  if y > TH - 1 then
    Result := 0;
  if y < 0 then
    Result := TH - 1;
end;

function Look(x, y, dr: integer): boolean;
begin
  Result := false;
  case dr of
    0: if Tile[x, CycY(y - 1)] <> clBlack then Result := true;
    1: if Tile[CycX(x + 1), CycY(y - 1)] <> clBlack then Result := true;
    2: if Tile[CycX(x + 1), y] <> clBlack then Result := true;
    3: if Tile[CycX(x + 1), CycY(y + 1)] <> clBlack then Result := true;
    4: if Tile[x, CycY(y + 1)] <> clBlack then Result := true;
    5: if Tile[CycX(x - 1), CycY(y + 1)] <> clBlack then Result := true;
    6: if Tile[CycX(x - 1), y] <> clBlack then Result := true;
    7: if Tile[CycX(x - 1), CycY(y - 1)] <> clBlack then Result := true;
  end;
end;

/// Right Left Up Down
function Look4(x, y: integer): integer;
begin
  Result := 0;
  for i: integer := 0 to 7 do
    case i of
      0: if Tile[x, CycY(y - 1)] <> clBlack then Result += 1;
      2: if Tile[CycX(x + 1), y] <> clBlack then Result += 1;
      4: if Tile[x, CycY(y + 1)] <> clBlack then Result += 1;
      6: if Tile[CycX(x - 1), y] <> clBlack then Result += 1;
    end;
end;

/// RU RD LD LU
function Look4_(x, y: integer): integer;
begin
  Result := 0;
  for i: integer := 0 to 7 do
    case i of
      1: if Tile[CycX(x + 1), CycY(y - 1)] <> clBlack then Result += 1;
      3: if Tile[CycX(x + 1), CycY(y + 1)] <> clBlack then Result += 1;
      5: if Tile[CycX(x - 1), CycY(y + 1)] <> clBlack then Result += 1;
      7: if Tile[CycX(x - 1), CycY(y - 1)] <> clBlack then Result += 1;
    end;
end;

procedure Swap(x, y, dr: integer);
var
  temp: Color;
begin
  temp := Tile[x, y];
  case dr of
    0: if Tile[x, y] <> Tile[x, CycY(y - 1)] then begin Tile[x, y] := Tile[x, CycY(y - 1)]; Tile[x, CycY(y - 1)] := temp end;
    1: if Tile[x, y] <> Tile[CycX(x + 1), CycY(y - 1)] then begin Tile[x, y] := Tile[CycX(x + 1), CycY(y - 1)]; Tile[CycX(x + 1), CycY(y - 1)] := temp end;
    2: if Tile[x, y] <> Tile[CycX(x + 1), y] then begin Tile[x, y] := Tile[CycX(x + 1), y]; Tile[CycX(x + 1), y] := temp end;
    3: if Tile[x, y] <> Tile[CycX(x + 1), CycY(y + 1)] then begin Tile[x, y] := Tile[CycX(x + 1), CycY(y + 1)]; Tile[CycX(x + 1), CycY(y + 1)] := temp end;
    4: if Tile[x, y] <> Tile[x, CycY(y + 1)] then begin Tile[x, y] := Tile[x, CycY(y + 1)]; Tile[x, CycY(y + 1)] := temp end;
    5: if Tile[x, y] <> Tile[CycX(x - 1), CycY(y + 1)] then begin Tile[x, y] := Tile[CycX(x - 1), CycY(y + 1)]; Tile[CycX(x - 1), CycY(y + 1)] := temp end;
    6: if Tile[x, y] <> Tile[CycX(x - 1), y] then begin Tile[x, y] := Tile[CycX(x - 1), y]; Tile[CycX(x - 1), y] := temp end;
    7: if Tile[x, y] <> Tile[CycX(x - 31), CycY(y - 1)] then begin Tile[x, y] := Tile[CycX(x - 1), CycY(y - 1)]; Tile[CycX(x - 1), CycY(y - 1)] := temp end;
  end;
end;

function Check(a, b, c: integer): boolean;
begin
  Result := false;
  case Rule of
    0: if a > Num then Result := true;
    1: if a < Num then Result := true;
    2: if a = Num then Result := true;
    3: if a <> Num then Result := true;
    
    4: if (b > Num1) and (c > Num2) then Result := true;
    5: if (b > Num1) and (c < Num2) then Result := true;
    6: if (b > Num1) and (c = Num2) then Result := true;
    7: if (b > Num1) and (c <> Num2) then Result := true;
    8: if (b < Num1) and (c > Num2) then Result := true;
    9: if (b < Num1) and (c < Num2) then Result := true;
    10: if (b < Num1) and (c = Num2) then Result := true;
    11: if (b < Num1) and (c <> Num2) then Result := true;
    
    12: if (b = Num1) and (c > Num2) then Result := true;
    13: if (b = Num1) and (c < Num2) then Result := true;
    14: if (b = Num1) and (c = Num2) then Result := true;
    15: if (b = Num1) and (c <> Num2) then Result := true;
    16: if (b <> Num1) and (c > Num2) then Result := true;
    17: if (b <> Num1) and (c < Num2) then Result := true;
    18: if (b <> Num1) and (c = Num2) then Result := true;
    19: if (b <> Num1) and (c <> Num2) then Result := true;
    
    20: if (b > Num1) or (c > Num2) then Result := true;
    21: if (b > Num1) or (c < Num2) then Result := true;
    22: if (b > Num1) or (c = Num2) then Result := true;
    23: if (b > Num1) or (c <> Num2) then Result := true;
    24: if (b < Num1) or (c > Num2) then Result := true;
    25: if (b < Num1) or (c < Num2) then Result := true;
    26: if (b < Num1) or (c = Num2) then Result := true;
    27: if (b < Num1) or (c <> Num2) then Result := true;
    
    28: if (b = Num1) or (c > Num2) then Result := true;
    29: if (b = Num1) or (c < Num2) then Result := true;
    30: if (b = Num1) or (c = Num2) then Result := true;
    31: if (b = Num1) or (c <> Num2) then Result := true;
    32: if (b <> Num1) or (c > Num2) then Result := true;
    33: if (b <> Num1) or (c < Num2) then Result := true;
    34: if (b <> Num1) or (c = Num2) then Result := true;
    35: if (b <> Num1) or (c <> Num2) then Result := true;
    
    36: if Round((Num1 + Num2) / 2) > b then Result := true;
    37: if Round((Num1 + Num2) / 2) < b then Result := true;
    38: if Round((Num1 + Num2) / 2) = b then Result := true;
    39: if Round((Num1 + Num2) / 2) <> b then Result := true;
  end;
end;

procedure Update_Cell(x, y: integer);
var
  done: boolean;
  dir: integer;
  free: integer := Look4(x, y);
  free_: integer := Look4_(x, y);
begin
  if Check(free + free_, free, free_) then
    if free + free_ > 0 then
    begin
      while not done do
      begin
        dir := Random(8);
        done := Look(x, y, dir);
      end;
      Swap(x, y, dir);
    end;
end;

procedure Update;
begin
  if Run then
  for i: integer := 0 to TH - 1 do
    for j: integer := 0 to TW - 1 do
      Update_Cell(j, i);
end;

procedure Resize;
begin
  Resized := true;
end;

begin
  SetWindowSize(W, H);
  CenterWindow;
  Window.Title := 'Random Cells';
  GraphABC.Font.Color := ARGB(192, 100, 255, 100);
  GraphABC.Font.Size := 12;
  OnKeyDown := KeyDown;
  OnKeyUp := KeyUp;
  OnMouseDown := MouseDown;
  OnMouseMove := MouseMove;
  OnMouseUp := MouseUp;
  OnResize := Resize;
  Num := Random(9);
  Num1 := Random(5);
  Num2 := Random(5);
  Rule := Random(40);
  Init;
  StartScreen;
  LockDrawing;
  while true do
  begin
    CycleUpdoot := 0;
    while CycleUpdoot < 100 do
    begin
      Changed := false;
      for i: integer := 0 to TH - 1 do
        for j: integer := 0 to TW - 1 do
          ForDetectChanges[j, i] := Tile[j, i];
      Update;
      for i: integer := 0 to TH - 1 do
        for j: integer := 0 to TW - 1 do
          if Tile[j, i] <> ForDetectChanges[j, i] then Changed := true;
      Control;
      if Resized then
      begin
        W := WindowWidth;
        H := WindowHeight;
        RawBmp := new Byte[WindowWidth * WindowHeight * 4];
        Resized := false;
      end;
      if Bmp <> nil then Bmp.Dispose;
      System.Threading.Monitor.Enter(GraphABC.GraphABCControl);
      Show;
      System.Threading.Monitor.Exit(GraphABC.GraphABCControl);
      //CycleUpdoot += 1;
    end;
    Init;
  end;
end.