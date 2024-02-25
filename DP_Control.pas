Unit DP_Control;
Uses GraphABC;
var
  BackColor, SelColor, MainColor: Color;
  ///Игровые клавиши
  UP,DOWN,LEFT,RIGHT,ENTER,R,SPACE, W_,A,S,D: boolean; //здесь можно ещё индикаторы добавить, если нужно
  ///Нажата ли кнопка клавиатуры
  KeyPressed: boolean;
  KeyCode: integer;
  ///Координаты мыши
  MouseX, MouseY: integer;
  ///Нажата ли кнопка мыши?
  MousePressed: boolean;
  ///Двигается ли мышь?
  MouseMoved: boolean;
  ///Код нажатой кнопки мыши
  MouseCode: integer;
  ///Изменился ли размер окна?
  Resized: boolean;
  Pause: integer;
  ActiveEdit := -1;
///Функция кнопка. Есть подсветка при наведении курсора. При нажатии возвращает true
function Button(X,Y,_W,_H: integer; Title: string): boolean;
begin
  Brush.Color := BackColor;
  FillRect(X,Y,X+_W,Y+_H);
  if (MouseX > X) and (MouseX < X+_W) and
     (MouseY > Y) and (MouseY < Y+_H) then
  begin
    Brush.Color := SelColor;
    if MousePressed then Result := true;
    while MousePressed do;
  end else
  Brush.Color := MainColor;
  FillRect(X+1,Y+1,X+_W-1,Y+_H-1);
  DrawTextCentered(X,Y,X+_W,Y+_H,Title);
end;
procedure KeyDown(key: integer);
begin
  case key of
    VK_UP: UP := true;
    VK_DOWN: DOWN := true;
    VK_LEFT: LEFT := true;
    VK_RIGHT: RIGHT := true;
    VK_ENTER: ENTER := true;
    VK_R: R := true;
    VK_SPACE: SPACE := true;
    VK_W: W_ := true;
    VK_S: S := true;
    VK_A: A := true;
    VK_D: D := true;
  end;
  KeyPressed := true;
  KeyCode := key;
end;
procedure KeyUp(key: integer);
begin
  case key of
    VK_UP: UP := false;
    VK_DOWN: DOWN := false;
    VK_LEFT: LEFT := false;
    VK_RIGHT: RIGHT := false;
    VK_ENTER: ENTER := false;
    VK_R: R := false;
    VK_SPACE: SPACE := false;
    VK_W: W_ := false;
    VK_S: S := false;
    VK_A: A := false;
    VK_D: D := false;
  end;
  KeyPressed := false;
  KeyCode := -11000;
end;
procedure MouseDown(x,y,mb: integer);
begin
  MouseX := x;
  MouseY := y;
  MousePressed := true;
  MouseCode := mb;
  Pause := 128;
  ActiveEdit := -1;
end;
procedure MouseMove(x,y,mb: integer);
begin
  MouseX := x;
  MouseY := y;
  MouseCode := mb;
  MouseMoved := true;
  Pause := 128;
end;
procedure MouseUp(x,y,mb: integer);
begin
  MousePressed := false;
end;
procedure Resize := Resized:= true;
begin
  OnKeyDown := KeyDown;
  OnKeyUp := KeyUp;
  OnMouseDown := MouseDown;
  OnMouseMove := MouseMove;
  OnMouseUp := MouseUp;
  OnResize := Resize;
end.