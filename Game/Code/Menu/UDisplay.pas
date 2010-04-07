unit UDisplay;

interface

uses Windows, SDL, UMenu, gl, glu, SysUtils;

type
  TDisplay = class
    ActualScreen:     PMenu;
    NextScreen:       PMenu;

    //fade-to-black-hack
    BlackScreen: Boolean;
    //popup hack
    NextScreenWithCheck: Pmenu;
    CheckOK: Boolean;

    h_DC:     HDC;
    h_RC:     HGLRC;

    Fade: Real;
    // fade-mod
    doFade:       Boolean;
    canFade:      Boolean;
    DoneOnShow:   Boolean;
    myFade:       integer;
    lastTime:     Cardinal;
    pTex:         array[1..2] of glUInt;
    TexW, TexH:   Cardinal;
    // end

    //FPS Counter
    FPSCounter: Cardinal;
    LastFPS:    Cardinal;
    mFPS:       Real;
    NextFPSSwap:Cardinal;
    
    //For Debug OSD
    OSD_LastError: String;

    function Draw: Boolean;
    procedure PrintScreen;
    constructor Create;
    // fade mod
    destructor Destroy;
    // end
    procedure ScreenShot;

    procedure DrawDebugInformation;
  end;

var
  Display:          TDisplay;

implementation

uses UGraphic, UTime, Math, Graphics, Jpeg, UFiles, UTexture, UIni, TextGL, UCommandLine;

constructor TDisplay.Create;
var
  i: integer;

begin
  inherited Create;

  //popup hack
  CheckOK:=False;
  NextScreen:=NIL;
  NextScreenWithCheck:=NIL;
  BlackScreen:=False;

  // fade mod
  myfade:=0;
  DoneOnShow := false;

  if Ini.ScreenFade=1 then
    doFade:=True
  else
    doFade:=False;

  canFade:=True;

  for i:= 1 to 2 do
  begin
    TexW := Round(Power(2, Ceil(Log2(ScreenW div Screens))));
    TexH := Round(Power(2, Ceil(Log2(ScreenH))));

    glGetError();

    glGenTextures(1, pTex[i]);
    if glGetError <> GL_NO_ERROR then canFade := False;

    glBindTexture(GL_TEXTURE_2D, pTex[i]);
    if glGetError <> GL_NO_ERROR then canFade := False;

    //glTexEnvi(GL_TEXTURE_2D, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    //if glGetError <> GL_NO_ERROR then canFade := False;

    glTexImage2D(GL_TEXTURE_2D, 0, 3, TexW, TexH, 0, GL_RGB, GL_UNSIGNED_BYTE, nil);
    if glGetError <> GL_NO_ERROR then canFade := False;

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    if glGetError <> GL_NO_ERROR then canFade := False;

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    if glGetError <> GL_NO_ERROR then canFade := False;
  end;

  //Set LastError for OSD to No Error
  OSD_LastError := 'No Errors';
end;

// fade mod
destructor TDisplay.Destroy;
begin
  if canFade then
    glDeleteTextures(1,@pTex);
  inherited Destroy;
end;
// end

function TDisplay.Draw: Boolean;
var
  S:            integer;
  Col:          Real;
  // fade mod
  myFade2:      Real;
  FadeW, FadeH: Real;
  currentTime:  Cardinal;
  glError:      glEnum;
  glErrorStr:   String;
  Ticks:        Cardinal;
  // end
begin
  Result := True;

  Col := 1;
  {if (ParamStr(1) = '-black') or (ParamStr(1) = '-fsblack') then
    Col := 0;    }

  glClearColor(Col, Col, Col , 0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  for S := 1 to Screens do begin
    ScreenAct := S;

//    if Screens = 1 then ScreenX := 0;
//    if (Screens = 2) and (S = 1) then ScreenX := -1;
//    if (Screens = 2) and (S = 2) then ScreenX := 1;
    ScreenX := 0;

    if S = 2 then TimeSkip := 0;

    glViewPort((S-1) * ScreenW div Screens, 0, ScreenW div Screens, ScreenH);

    //popup hack
    // check was successful... move on
    if CheckOK then
      if assigned (NextScreenWithCheck)then
      begin
        NextScreen:=NextScreenWithCheck;
        NextScreenWithCheck := NIL;
        CheckOk:=False;
      end
      else
        BlackScreen:=True; // end of game - fade to black before exit
    //end popup hack

//    ActualScreen.SetAnimationProgress(1);
    if (not assigned (NextScreen)) and (not BlackScreen) then begin
      ActualScreen.Draw;
      //popup mod
      if ScreenPopupError <> NIL then
        if ScreenPopupError.Visible then
          ScreenPopupError.Draw
      else
      if ScreenPopupCheck <> NIL then
        if ScreenPopupCheck.Visible then
          ScreenPopupCheck.Draw
      else
      if ScreenPopupHelp <> NIL then
        if ScreenPopupHelp.Visible then
          ScreenPopupHelp.Draw;
      //popup end
      // fade mod
      myfade:=0;
      if (Ini.ScreenFade=1) and canFade then
        doFade:=True
      else if Ini.ScreenFade=0 then
        doFade:=False;
      // end
    end
    else
    begin
      // check if we had an initialization error (canfade=false, dofade=true)
      if doFade and not canFade then begin
        doFade:=False; //disable fading
        ScreenPopupError.ShowPopup('Error initializing\nfade texture\n\nfading\ndisabled'); //show error message
      end;

      if doFade and canFade then
      begin
        // fade mod
        //Create Fading texture if we're just starting
        if myfade = 0 then
        begin
          //glViewPort(0, 0, 512, 512);
          ActualScreen.Draw;
          glGetError();

          glBindTexture(GL_TEXTURE_2D, pTex[S]);
          glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (S-1) * ScreenW div Screens, 0,
            ScreenW div Screens, ScreenH);

          glError:=glGetError;
          if glError <> GL_NO_ERROR then
          begin
            canFade := False;
            case glError of
              GL_INVALID_ENUM: glErrorStr:='INVALID_ENUM';
              GL_INVALID_VALUE: glErrorStr:='INVALID_VALUE';
              GL_INVALID_OPERATION: glErrorStr:='INVALID_OPERATION';
              GL_STACK_OVERFLOW: glErrorStr:='STACK_OVERFLOW';
              GL_STACK_UNDERFLOW: glErrorStr:='STACK_UNDERFLOW';
              GL_OUT_OF_MEMORY: glErrorStr:='OUT_OF_MEMORY';
              else glErrorStr:='unknown error';
            end;
            ScreenPopupError.ShowPopup('Error copying\nfade texture\n('+glErrorStr+')\nfading\ndisabled'); //show error message
          end;
          //glViewPort((S-1) * ScreenW div Screens, 0, ScreenW div Screens, ScreenH);

          lastTime:=GetTickCount;
          if (S=2) or (Screens = 1) then
            myfade:=myfade+1;
        end; // end texture creation in first fading step

        // blackscreen-hack
        if (not BlackScreen) AND (S = 1) and not DoneOnShow then
        begin
          NextScreen.onShow;
          DoneOnShow := true;
        end;

        //do some time-based fading
        currentTime:=GetTickCount;
        if (currentTime > lastTime+30) and (S=1) then
        begin
          myfade:=myfade+4;
          lastTime:=currentTime;
        end;

//      LastFade := Fade;   // whatever
//      Fade := Fade -0.999; // start fading out


//      ActualScreen.ShowFinish := false; // no purpose?

//      ActualScreen.SetAnimationProgress(Fade-1); // nop?

        // blackscreen-hack
        if not BlackScreen then
          NextScreen.Draw // draw next screen
        else begin
          glClearColor(0, 0, 0 , 0);
          glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
        end;

      // and draw old screen over it... slowly fading out
        myfade2:=(myfade*myfade)/10000;
        FadeW := (ScreenW div Screens)/TexW;
        FadeH := ScreenH/TexH;

        glBindTexture(GL_TEXTURE_2D, pTex[S]);
        glColor4f(1, 1, 1, (1000-myfade*myfade)/1000); // strange calculation - alpha gets negative... but looks good this way

        glEnable(GL_TEXTURE_2D);
        //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
        glBegin(GL_QUADS);
          glTexCoord2f((0+myfade2)*FadeW, (0+myfade2)*FadeH);
          glVertex2f(0,   RenderH);

          glTexCoord2f((0+myfade2)*FadeW, (1-myfade2)*FadeH);
          glVertex2f(0,   0);

          glTexCoord2f((1-myfade2)*FadeW, (1-myfade2)*FadeH);
          glVertex2f(RenderW, 0);

          glTexCoord2f((1-myfade2)*FadeW, (0+myfade2)*FadeH);
          glVertex2f(RenderW, RenderH);
        glEnd;
        glDisable(GL_BLEND);
        glDisable(GL_TEXTURE_2D);
      end
      else
        // blackscreen hack
        if (not BlackScreen) AND (S = 1) then
          NextScreen.OnShow;

      if ((myfade > 40) or (not doFade) or (not canFade)) And (S = 1) then begin // fade out complete...
        //if not DoneOnShow then
        //      ScreenPopupError.ShowPopup('Wheres OnShow ?'); //show error message
        DoneOnShow := false;
        myFade:=0;
        ActualScreen.onHide;
        ActualScreen.ShowFinish:=False;
        ActualScreen:=NextScreen;
        NextScreen := nil;
        if not blackscreen then
        begin
          ActualScreen.onShowFinish;
          ActualScreen.ShowFinish := true;
        end
        else
        begin
          Result:=False;
          Break;
        end;
      // end of fade mod
      end;
    end; // if

    //Calculate FPS
    Ticks := GetTickCount;
    if (Ticks >= NextFPSSwap) then
    begin
      LastFPS := FPSCounter * 4;

      mFPS := (mFPS+LastFPS)/2;

      FPSCounter := 0;
      NextFPSSwap := Ticks + 250;
    end;

    if(S = 1) then
      Inc(FPSCounter);

    //Draw OSD only on first Screen if Debug Mode is enabled
    if ((Ini.Debug = 1) OR (Params.Debug)) AND (S=1) then
      DrawDebugInformation;
      
  end; // for S
//  SwapBuffers(h_DC);
end;

{function TDisplay.Fade(FadeIn : Boolean; Steps : UInt8): UInt8;
begin
  Self.FadeIn := FadeIn;
  FadeStep := (SizeOf(FadeStep) * $FF) div Steps;
  ActualStep := $FF;
  Result := $FF div FadeStep;
end;}

procedure TDisplay.PrintScreen;
var
  Bitmap:     TBitmap;
  Jpeg:       TJpegImage;
  X, Y:       integer;
  Num:        integer;
  FileName:   string;
begin
  for Num := 1 to 9999 do begin
    FileName := IntToStr(Num);
    while Length(FileName) < 4 do FileName := '0' + FileName;
    FileName := ScreenshotsPath + 'screenshot' + FileName + '.jpg';
    if not FileExists(FileName) then break
  end;

  glReadPixels(0, 0, ScreenW, ScreenH, GL_RGBA, GL_UNSIGNED_BYTE, @PrintScreenData[0]);
  Bitmap := TBitmap.Create;
  Bitmap.Width := ScreenW;
  Bitmap.Height := ScreenH;

  for Y := 0 to ScreenH-1 do
    for X := 0 to ScreenW-1 do
      Bitmap.Canvas.Pixels[X, Y] := PrintScreenData[(ScreenH-1-Y) * ScreenW + X] and $00FFFFFF;

  Jpeg := TJpegImage.Create;
  Jpeg.Assign(Bitmap);
  Bitmap.Free;
  Jpeg.CompressionQuality := 95;//90;
  Jpeg.SaveToFile(FileName);
  Jpeg.Free;
end;

procedure TDisplay.ScreenShot;
 var F : file;
     FileInfo: BITMAPINFOHEADER;
     FileHeader : BITMAPFILEHEADER;
     pPicData:Pointer;
     FileName: String;
     Num: Integer;
begin
  //bilddatei Suchen
  for Num := 1 to 9999 do begin
    FileName := IntToStr(Num);
    while Length(FileName) < 4 do FileName := '0' + FileName;
    FileName := ScreenshotsPath + FileName + '.BMP';
    if not FileExists(FileName) then break
  end;

 //Speicher f�r die Speicherung der Header-Informationen vorbereiten
 ZeroMemory(@FileHeader, SizeOf(BITMAPFILEHEADER));
 ZeroMemory(@FileInfo, SizeOf(BITMAPINFOHEADER));
 
 //Initialisieren der Daten des Headers
 FileHeader.bfType := 19778; //$4D42 = 'BM'
 FileHeader.bfOffBits := SizeOf(BITMAPINFOHEADER)+SizeOf(BITMAPFILEHEADER);
 
 //Schreiben der Bitmap-Informationen
 FileInfo.biSize := SizeOf(BITMAPINFOHEADER);
 FileInfo.biWidth := ScreenW;
 FileInfo.biHeight := ScreenH;
 FileInfo.biPlanes := 1;
 FileInfo.biBitCount := 32;
 FileInfo.biSizeImage := FileInfo.biWidth*FileInfo.biHeight*(FileInfo.biBitCount div 8);
 
 //Gr��enangabe auch in den Header �bernehmen
 FileHeader.bfSize := FileHeader.bfOffBits + FileInfo.biSizeImage;
 
 //Speicher f�r die Bilddaten reservieren
 GetMem(pPicData, FileInfo.biSizeImage);
 try
  //Bilddaten von OpenGL anfordern (siehe oben)
  glReadPixels(0, 0, ScreenW, ScreenH, GL_BGRA_EXT, GL_UNSIGNED_BYTE, pPicData);
 
  //Und den ganzen M�ll in die Datei schieben ;-)
  //Moderne Leute nehmen daf�r auch Streams ...
  AssignFile(f, Filename);
  Rewrite( f,1 );
  try
   BlockWrite(F, FileHeader, SizeOf(BITMAPFILEHEADER));
   BlockWrite(F, FileInfo, SizeOf(BITMAPINFOHEADER));
   BlockWrite(F, pPicData^, FileInfo.biSizeImage );
  finally
   CloseFile(f);
  end;
 finally
  //Und den angeforderten Speicher wieder freigeben ...
  FreeMem(pPicData, FileInfo.biSizeImage);
 end;
end;

//------------
// DrawDebugInformation - Procedure draw FPS and some other Informations on Screen
//------------
procedure TDisplay.DrawDebugInformation;
begin
  //Some White Background for information
  glEnable(GL_BLEND);
  glDisable(GL_TEXTURE_2D);
  glColor4f(1, 1, 1, 0.5);
  glBegin(GL_QUADS);
    glVertex2f(690, 57);
    glVertex2f(690, 0);
    glVertex2f(800, 0);
    glVertex2f(800, 57);
  glEnd;
  glDisable(GL_BLEND);

  //Set Font Specs
  SetFontStyle(0);
  SetFontSize(7);
  SetFontItalic(False);
  glColor4f(0, 0, 0, 1);

  //Draw Text

  //FPS
  SetFontPos(695, 0);
  glPrint (PChar('aFPS: ' + InttoStr(LastFPS)));

  SetFontPos(695, 13);
  glPrint (PChar('mFPS: ' + InttoStr(round(mFPS))));

  //RSpeed
  SetFontPos(695, 26);
  glPrint (PChar('RSpeed: ' + InttoStr(Round(1000 * TimeMid))));

  //LastError
  SetFontPos(695, 39);
  glColor4f(1, 0, 0, 1);
  glPrint (PChar(OSD_LastError));

  glColor4f(1, 1, 1, 1);
end;

end.
