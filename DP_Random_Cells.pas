{
  Рандомный залипательный клеточный автомат
  Первоначальная идея - найти правила для клеточного автомата,
  которые позволяют строить полноценную логику, подобно игре Жизнь Джона Конуэя,
  также, хочется найти комбинацию правил для построения лабиринтов.
  Да, я знаю что лабиринт можно без клеточного автомата создать.
TODO:
  - исправить баг, проявляющийся на пресете 3, 3, 3, 32, 320
                                            4, 1, 1, 14, 1524
  - исправить баг диагональной вытянутости некоторых пресетов
  - исправить поломки при переключении режима просмотра
  - исправить поломки при приостановке
  - исправить жор проца при простое в меню и диалоговых окнах
  - исправить отрисовку при масштабировании
  - исправить управление - заменить Key_Code на переменные для конкретных переменных
  - создать интерактивную библиотеку сохранённых залипалок
  - "сенсорное меню" - все настройки на экране
  - сохранение пресета на S - сохраняется стартовое значение и комбинация правил чтобы можно было полностью воспроизвести ситуацию
  - добавить управление скоростью и пропуском кадров
  - добавить откат к старту текущего пресета
  - всегда сохранять стартовое состояние до запуска
  - разделить и централизовать Render и Update
  - добавить настройку памяти - пиксель может помнить своё предыдущее состояние и предыдущее состояние соседей
  - в зависимости от предыдущего состояния пиксель либо идёт в случайном направлении либо реагирует на окружение
  - добавить обратные условия - на исчезновение и на появление
  - убрать неэффективные, взаимоисключающие И ПОВТОРЯЮЩИЕСЯ условия
  - добавить комбинации Rule, использующие Num, Num1 и Num2 во всех вариантах
  - вместо отдельных условий появления установить рандомный массив для действий по триггерам
    Triggers[0,1,2,3,4,5,6,7,8, 0,1,2,3,4, 0,1,2,3,4] 0..18 19 значений в массиве,
    каждая позиция может иметь одно из трёх значений: "Enable", "Disable", "None"
  - Triggers содержит все конкретные варианты окружающих пикселей (9 штук), все количественные подсчёты по вертикали, горизонтали и диагоналям, также, информация о желаемой цифре, правиле и поведении (использование рандома etc), возможно что-то из этого будет лишним, внимательно проверить и исключить избыточные правила
  - массивы заполняются случайным образом, если True, то значение меняется, если False, то значение не меняется при таких параметрах
  - скомбинировать Triggers и Rule и получить ультрапак комбинаций
  - откат обновления пресета
  - опция размытия
  - настройка цветов
  - ВОЙНА КЛЕТОК - КРАСНЫЕ ПРОТИВ СИНИХ (Красные двигаются, а синие размножаются!!)
  + исправить баг автоматического добавления пикселя от курсора
}
Uses GraphABC, System.Drawing, System.Drawing.Imaging, DP_Control;

var
  // Параметры
  /// Использовать более быструю (но некрасивую) отрисовку
  UseFasterRender := False;
  /// Перемещать пиксель в случайную сторону вместо прямого следования правилу активации
  Random_Cell_Update := False;
  /// Обновлять не все пиксели по порядку, а случайные
  Update_Random_Cells := False;
  /// Использовать буфер чтобы предотвратить неточности
  UsesBuffer := True;
  /// Ширина полотна
  TW := 50;
  /// Высота полотна
  TH := 50;
  /// Размер пикселя при отрисовке
  PS := 10;
  /// Сколько пропускать кадров
  SkipFrames := 1;
  /// Сколько кадров пропущено
  SkippedFrames: integer;
  /// Масштабирование при отрисовке (убрать в будущем)
  Scale: integer := 5;
  
  // Технические переменные
  W := TW * PS;
  H := TH * PS;
  RawBmp := new Byte[W * H * 4];
  MaketBmp := new Byte[TW * TH * 4];
  Bmp: Bitmap;
  Tile: array[,] of Color;
  Buffer: array[,] of Color;
  ForDetectChanges: array[,] of Color;
  ToSpawn := Integer(Random(0, TW * TH));
  ShowMaket: boolean;
  ShowNumbers: boolean := true;
  Run: boolean := true;
  /// Сколько соседей у клетки дожно быть всего, по кресту и по диагонали
  Num, Num1, Num2: integer;
  /// Правило обработки клеток
  Rule: integer;
  /// Поле изменено
  Changed: boolean;

/// Преобразовать массив байт в изображение
function BytesToImage(bytes: array of byte; Width: integer): Bitmap;
begin
  var Height := (bytes.Length div 4) div Width;
  result := new Bitmap(Width, Height);
  var rect := new Rectangle(0, 0, Width, Height);
  var bmData := result.LockBits(rect, ImageLockMode.WriteOnly, result.PixelFormat);
  System.Runtime.InteropServices.Marshal.Copy(bytes, 0, bmData.Scan0, bytes.Length);
  result.UnlockBits(bmData);
end;

procedure Init;
var
  Spawned: integer;
  Sx, Sy: integer;
begin
  SetLength(Tile, TW, TH);
  SetLength(Buffer, TW, TH);
  SetLength(ForDetectChanges, TW, TH);
  for i: integer := 0 to TH - 1 do
    for j: integer := 0 to TW - 1 do
      Tile[j, i] := clBlack;
  while Spawned < ToSpawn do//TW * TH / 2 do
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

procedure NormalRender;
begin
  for i: integer := 0 to TH - 1 do
    for j: integer := 0 to TW - 1 do
    begin
      GraphABC.Brush.Color := Tile[j, i];
      FillRect(W div TW * j, H div TH * i, W div TW * (j + 1), H div TH * (i + 1));
    end;
end;

procedure FasterRender;
begin
  DrawMaket(MaketBmp);
  Bmp := BytesToImage(MaketBmp, TW);
  GraphBufferGraphics.DrawImage(Bmp, 0, 0, W, H);
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
    if UseFasterRender then
      FasterRender
    else
      NormalRender;
    
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
  //Rules
  if ShowNumbers then
  begin
    GraphABC.Brush.Color := ARGB(128, 100, 100, 100);
    GraphABC.Font.Color := ARGB(128, 255, 255, 255);
    var State: string;
    if Changed then
      State := 'running'
    else
      State := 'stopped';
    TextOut(0, H - 20, Num + ', ' + Num1 + ', ' + Num2 + ', ' + Rule + ', ' + ToSpawn + ', ' + State);
  end;
  Redraw;
end;

procedure Enter_Rules;
begin
  ClearWindow(clBlack);
  DrawTextCentered(0, 0, W, H,
    'Введите новые правила одной строкой' + newline +
    'через запятую в следующем формате:' + newline +
    'Num (0-8), Num1 (0-4), Num2 (0-4), Rule (0-39), ToSpawn' + newline +
    'Например:' + newline +
    '1, 2, 3, 4, 400');
  Redraw;
  var New_Rules: string;
  Read(New_Rules);
  var Rules := New_Rules.Split(',');
  Num := Rules[0].ToInteger;
  Num1 := Rules[1].ToInteger;
  Num2 := Rules[2].ToInteger;
  Rule := Rules[3].ToInteger;
  ToSpawn := Rules[4].ToInteger;
  Init;
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
  while not KeyPressed do Sleep(8);
  
  ClearWindow(clBlack);
  DrawTextCentered(0, 0, W, H,
    'На одном окне стандартного размера всё не уместилось' + newline +
    'Enter - задать все правила вручную' + newline +
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
  while not KeyPressed do Sleep(8);
end;

procedure Control;
begin
  if not Changed then begin Show; Redraw; while not KeyPressed and
     not MousePressed do end; //Простой процессора тоже полезен
  if MousePressed then
    if (MouseX < W) and (MouseX > 0) and
       (MouseY < H) and (MouseY > 0) and
        ShowMaket and (MouseCode = 2) then
      Tile[Round((MouseX - (W / TW) / 2) / (W / TW)),
           Round((MouseY - (H / TH) / 2) / (H / TH))] := clGreen
    else
      Tile[Round((MouseX - (W / TW) / 2) / (W / TW)),
           Round((MouseY - (H / TH) / 2) / (H / TH))] := clBlack;
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
    begin
      ToSpawn := Integer(Random(0, TW * TH));//TW * TH / 2;
      Init;
    end;
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
      ToSpawn := Integer(Random(0, TW * TH));//TW * TH / 2;
      Init;
      Num := Random(9);
      Num1 := Random(5);
      Num2 := Random(5);
      Rule := Random(40);
    end;
    if KeyCode = VK_Enter then
      Enter_Rules;
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
    0: if Tile[x,           CycY(y - 1)] <> clBlack then Result := true;
    1: if Tile[CycX(x + 1), CycY(y - 1)] <> clBlack then Result := true;
    2: if Tile[CycX(x + 1),           y] <> clBlack then Result := true;
    3: if Tile[CycX(x + 1), CycY(y + 1)] <> clBlack then Result := true;
    4: if Tile[x,           CycY(y + 1)] <> clBlack then Result := true;
    5: if Tile[CycX(x - 1), CycY(y + 1)] <> clBlack then Result := true;
    6: if Tile[CycX(x - 1),           y] <> clBlack then Result := true;
    7: if Tile[CycX(x - 1), CycY(y - 1)] <> clBlack then Result := true;
  end;
end;

/// Right Left Up Down
function LookHorizontalVertical(x, y: integer): integer;
begin
  Result := 0;
  if Tile[x, CycY(y - 1)] <> clBlack then Result += 1;
  if Tile[CycX(x + 1), y] <> clBlack then Result += 1;
  if Tile[x, CycY(y + 1)] <> clBlack then Result += 1;
  if Tile[CycX(x - 1), y] <> clBlack then Result += 1;
end;

/// RU RD LD LU
function LookDiagonal(x, y: integer): integer;
begin
  Result := 0;
  if Tile[CycX(x + 1), CycY(y - 1)] <> clBlack then Result += 1;
  if Tile[CycX(x + 1), CycY(y + 1)] <> clBlack then Result += 1;
  if Tile[CycX(x - 1), CycY(y + 1)] <> clBlack then Result += 1;
  if Tile[CycX(x - 1), CycY(y - 1)] <> clBlack then Result += 1;
end;

procedure Swap(x, y, dr: integer);
var
  temp: Color;
begin
  if UsesBuffer then
  begin
    case dr of
      0: begin Buffer[x, y] := Tile[x,           CycY(y - 1)]; Buffer[x, CycY(y - 1)] := Tile[x, y] end;
      1: begin Buffer[x, y] := Tile[CycX(x + 1), CycY(y - 1)]; Buffer[CycX(x + 1), CycY(y - 1)] := Tile[x, y] end;
      2: begin Buffer[x, y] := Tile[CycX(x + 1),           y]; Buffer[CycX(x + 1), y] := Tile[x, y] end;
      3: begin Buffer[x, y] := Tile[CycX(x + 1), CycY(y + 1)]; Buffer[CycX(x + 1), CycY(y + 1)] := Tile[x, y] end;
      4: begin Buffer[x, y] := Tile[x,           CycY(y + 1)]; Buffer[x, CycY(y + 1)] := Tile[x, y] end;
      5: begin Buffer[x, y] := Tile[CycX(x - 1), CycY(y + 1)]; Buffer[CycX(x - 1), CycY(y + 1)] := Tile[x, y] end;
      6: begin Buffer[x, y] := Tile[CycX(x - 1),           y]; Buffer[CycX(x - 1), y] := Tile[x, y] end;
      7: begin Buffer[x, y] := Tile[CycX(x - 1), CycY(y - 1)]; Buffer[CycX(x - 1), CycY(y - 1)] := Tile[x, y] end;
    end;
  end
  else
  begin
    temp := Tile[x, y];
    case dr of
      0: begin Tile[x, y] := Tile[x,           CycY(y - 1)]; Tile[x, CycY(y - 1)] := temp end;
      1: begin Tile[x, y] := Tile[CycX(x + 1), CycY(y - 1)]; Tile[CycX(x + 1), CycY(y - 1)] := temp end;
      2: begin Tile[x, y] := Tile[CycX(x + 1),           y]; Tile[CycX(x + 1), y] := temp end;
      3: begin Tile[x, y] := Tile[CycX(x + 1), CycY(y + 1)]; Tile[CycX(x + 1), CycY(y + 1)] := temp end;
      4: begin Tile[x, y] := Tile[x,           CycY(y + 1)]; Tile[x, CycY(y + 1)] := temp end;
      5: begin Tile[x, y] := Tile[CycX(x - 1), CycY(y + 1)]; Tile[CycX(x - 1), CycY(y + 1)] := temp end;
      6: begin Tile[x, y] := Tile[CycX(x - 1),           y]; Tile[CycX(x - 1), y] := temp end;
      7: begin Tile[x, y] := Tile[CycX(x - 1), CycY(y - 1)]; Tile[CycX(x - 1), CycY(y - 1)] := temp end;
    end;
  end;
end;

function Check(a, b, c: integer): boolean;
begin
  Result := false;
  case Rule of
    0: Result := a > Num;
    1: Result := a < Num;
    2: Result := a = Num;
    3: Result := a <> Num;
    
    4: Result := (b > Num1) and (c > Num2);
    5: Result := (b > Num1) and (c < Num2);
    6: Result := (b > Num1) and (c = Num2);
    7: Result := (b > Num1) and (c <> Num2);
    8: Result := (b < Num1) and (c > Num2);
    9: Result := (b < Num1) and (c < Num2);
    10: Result := (b < Num1) and (c = Num2);
    11: Result := (b < Num1) and (c <> Num2);
    
    12: Result := (b = Num1) and (c > Num2);
    13: Result := (b = Num1) and (c < Num2);
    14: Result := (b = Num1) and (c = Num2);
    15: Result := (b = Num1) and (c <> Num2);
    16: Result := (b <> Num1) and (c > Num2);
    17: Result := (b <> Num1) and (c < Num2);
    18: Result := (b <> Num1) and (c = Num2);
    19: Result := (b <> Num1) and (c <> Num2);
    
    20: Result := (b > Num1) or (c > Num2);
    21: Result := (b > Num1) or (c < Num2);
    22: Result := (b > Num1) or (c = Num2);
    23: Result := (b > Num1) or (c <> Num2);
    24: Result := (b < Num1) or (c > Num2);
    25: Result := (b < Num1) or (c < Num2);
    26: Result := (b < Num1) or (c = Num2);
    27: Result := (b < Num1) or (c <> Num2);
    
    28: Result := (b = Num1) or (c > Num2);
    29: Result := (b = Num1) or (c < Num2);
    30: Result := (b = Num1) or (c = Num2);
    31: Result := (b = Num1) or (c <> Num2);
    32: Result := (b <> Num1) or (c > Num2);
    33: Result := (b <> Num1) or (c < Num2);
    34: Result := (b <> Num1) or (c = Num2);
    35: Result := (b <> Num1) or (c <> Num2);
    
    36: Result := Round((Num1 + Num2) / 2) > b;
    37: Result := Round((Num1 + Num2) / 2) < b;
    38: Result := Round((Num1 + Num2) / 2) = b;
    39: Result := Round((Num1 + Num2) / 2) <> b;
  end;
end;

procedure Update_Cell(x, y: integer);
var
  done: boolean;
  dir: integer;
  freeHV: integer := LookHorizontalVertical(x, y);
  freeD: integer := LookDiagonal(x, y);
  checkResult := Check(freeHV + freeD, freeHV, freeD);
begin
  if Random_Cell_Update then
  begin
    if checkResult then
      if freeHV + freeD > 0 then
      begin
        while not done do
        begin
          dir := Random(8);
          done := Look(x, y, dir);
        end;
        Swap(x, y, dir);
      end;
  end
  else
  if UsesBuffer then
  begin
    if checkResult = True then
      Buffer[x, y] := clGreen
    else
      Buffer[x, y] := clBlack;
  end
    else
  if checkResult = True then
    Tile[x, y] := clGreen
  else
    Tile[x, y] := clBlack;
end;

procedure Update_Cells;
begin
  if Run then
  begin
    for i: integer := 0 to TH - 1 do
      for j: integer := 0 to TW - 1 do
        if Update_Random_Cells then
          Update_Cell(Random(TW), Random(TH))
            else
          Update_Cell(j, i);
    if UsesBuffer then
      Tile := Buffer;
  end;
end;

procedure InitProgram;
begin
  SetWindowSize(W, H);
  CenterWindow;
  Window.Title := 'Random Cells';
  GraphABC.Font.Color := ARGB(192, 100, 255, 100);
  GraphABC.Font.Size := 12;
  LockDrawing;
  Num := Random(9);
  Num1 := Random(5);
  Num2 := Random(5);
  Rule := Random(40);
  Init;
  StartScreen;
end;

procedure Render;
begin
  if Bmp <> nil then Bmp.Dispose;
  System.Threading.Monitor.Enter(GraphABC.GraphABCControl);
  Show;
  System.Threading.Monitor.Exit(GraphABC.GraphABCControl);
end;

procedure Update;
begin
  SkippedFrames := 0;
  while SkippedFrames < SkipFrames do
  begin
    Changed := false;
    for i: integer := 0 to TH - 1 do
      for j: integer := 0 to TW - 1 do
        ForDetectChanges[j, i] := Tile[j, i];
    Update_Cells;
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
    SkippedFrames += 1;
  end;
end;

begin
  InitProgram;
  while true do
  begin
    Render;
    Update;
  end;
end.