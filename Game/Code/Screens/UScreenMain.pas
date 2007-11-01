unit UScreenMain;

interface

uses
  UMenu, SDL, UDisplay, UMusic, UFiles, SysUtils, UThemes, ULCD, ULight;

type
  TScreenMain = class(TMenu)
    public
      TextDescription:        integer;
      TextDescriptionLong:    integer;

      constructor Create; override;
      function ParseInput(PressedKey: Cardinal; ScanCode: byte; PressedDown: Boolean): Boolean; override;
      procedure onShow; override;
      procedure InteractNext; override;
      procedure InteractPrev; override;
      procedure InteractInc; override;
      procedure InteractDec; override;
      procedure UpdateLCD;
      procedure SetAnimationProgress(Progress: real); override;
      //function Draw: boolean; override;
  end;

implementation

uses Windows, UGraphic, UMain, UIni, UTexture, USongs, Textgl, opengl, ULanguage, UParty, UDLLManager, UScreenCredits, USkins, ULog;


function TScreenMain.ParseInput(PressedKey: Cardinal; ScanCode: byte; PressedDown: Boolean): Boolean;
var
I: Integer;
SDL_ModState:  Word;
begin
  Result := true;

  SDL_ModState := SDL_GetModState and (KMOD_LSHIFT + KMOD_RSHIFT
    + KMOD_LCTRL + KMOD_RCTRL + KMOD_LALT  + KMOD_RALT);

  //Deactivate Credits when Key is pressed
//  if Credits_Visible then
//  begin
//    Credits_Visible := False;
//    exit;
//  end;

  If (PressedDown) Then
  begin // Key Down
    case PressedKey of
      SDLK_Q:
        begin
          Result := false;
        end;

      SDLK_ESCAPE,
      SDLK_BACKSPACE :
        begin
          Result := False;
        end;

      SDLK_C:
        begin
          if (SDL_ModState = KMOD_LALT) then
          begin
            //If CreditsScreen is not Created -> Then Create
            If (ScreenCredits = nil) then
            begin
              try
                //Display White Loading Text
                SetFontStyle(2); //Font: Outlined1
                SetFontSize(12);
                SetFontItalic(False);
                SetFontPos (400 - glTextWidth ('Loading Credits ...')/2, 250); //Position
                glColor4f(1,1,1,1);
                glPrint('Loading Credits ...');
                SwapBuffers;

                ScreenCredits    :=       TScreenCredits.Create;
              except
                Log.LogError ('Couldn''t Create Credits Screen');
              end;
            end;

            If (ScreenCredits <> nil) then
            begin
              Music.PlayStart;
              FadeTo(@ScreenCredits);
            end;
          end;
        end;
      SDLK_M:
        begin
          if (Ini.Players >= 1) AND (Length(DLLMan.Plugins)>=1) then
          begin
            Music.PlayStart;
            FadeTo(@ScreenPartyOptions);
          end;
        end;

      SDLK_S:
        begin
          Music.PlayStart;
          FadeTo(@ScreenStatMain);
        end;

      SDLK_E:
        begin
          Music.PlayStart;
          FadeTo(@ScreenEdit);
        end;

      SDLK_RETURN:
        begin
          //Solo
          if (Interaction = 0) then
          begin
            if (Length(Songs.Song) >= 1) then
            begin
              Music.PlayStart;
              if (Ini.Players >= 0) and (Ini.Players <= 3) then PlayersPlay := Ini.Players + 1;
              if (Ini.Players = 4) then PlayersPlay := 6;

              ScreenName.Goto_SingScreen := False;
              FadeTo(@ScreenName);
            end
            else //show error message
              ScreenPopupError.ShowPopup(Language.Translate('ERROR_NO_SONGS'));
          end;

          //Multi
          if Interaction = 1 then begin
            if (Length(Songs.Song) >= 1) then
            begin
              if (Length(DLLMan.Plugins)>=1) then
              begin
                Music.PlayStart;
                FadeTo(@ScreenPartyOptions);
              end
              else //show error message, No Plugins Loaded
              ScreenPopupError.ShowPopup(Language.Translate('ERROR_NO_PLUGINS'));
            end
            else //show error message, No Songs Loaded
              ScreenPopupError.ShowPopup(Language.Translate('ERROR_NO_SONGS'));
          end;

          //Stats
          if Interaction = 2 then begin
            Music.PlayStart;
            FadeTo(@ScreenStatMain);
          end;

          //Editor
          if Interaction = 3 then begin
            Music.PlayStart;
            FadeTo(@ScreenEdit);
          end;

          //Options
          if Interaction = 4 then begin
            Music.PlayStart;
            FadeTo(@ScreenOptions);
          end;

          //Exit
          if Interaction = 5 then begin
            Result := false;
          end;
        end;
      // Up and Down could be done at the same time,
      // but I don't want to declare variables inside
      // functions like this one, called so many times
      SDLK_DOWN:    InteractInc;
      SDLK_UP:      InteractDec;
      SDLK_RIGHT:   InteractNext;
      SDLK_LEFT:    InteractPrev;
    end;
  end
  else // Key Up
    case PressedKey of
      SDLK_RETURN :
        begin
        end;
    end;
end;

constructor TScreenMain.Create;
var
  I:    integer;
begin
  inherited Create;

  //----------------
  //Attention ^^:
  //New Creation Order needed because of LoadFromTheme
  //and Button Collections.
  //At First Custom Texts and Statics
  //Then LoadFromTheme
  //after LoadFromTheme the Buttons and Selects
  //----------------


  TextDescription := AddText(Theme.Main.TextDescription);
  TextDescriptionLong := AddText(Theme.Main.TextDescriptionLong);

  LoadFromTheme(Theme.Main);

  AddButton(Theme.Main.ButtonSolo);
  AddButton(Theme.Main.ButtonMulti);
  AddButton(Theme.Main.ButtonStat);
  AddButton(Theme.Main.ButtonEditor);
  AddButton(Theme.Main.ButtonOptions);
  AddButton(Theme.Main.ButtonExit);

  Interaction := 0;
end;

procedure TScreenMain.onShow;
begin
  LCD.WriteText(1, '  Choose mode:  ');
  UpdateLCD;
end;

procedure TScreenMain.InteractNext;
begin
  inherited InteractNext;
  Text[TextDescription].Text := Theme.Main.Description[Interaction];
  Text[TextDescriptionLong].Text := Theme.Main.DescriptionLong[Interaction];
  UpdateLCD;
  Light.LightOne(1, 200);
end;

procedure TScreenMain.InteractPrev;
begin
  inherited InteractPrev;
  Text[TextDescription].Text := Theme.Main.Description[Interaction];
  Text[TextDescriptionLong].Text := Theme.Main.DescriptionLong[Interaction];
  UpdateLCD;
  Light.LightOne(0, 200);
end;

procedure TScreenMain.InteractDec;
begin
  inherited InteractDec;
  Text[TextDescription].Text := Theme.Main.Description[Interaction];
  Text[TextDescriptionLong].Text := Theme.Main.DescriptionLong[Interaction];
  UpdateLCD;
  Light.LightOne(0, 200);
end;

procedure TScreenMain.InteractInc;
begin
  inherited InteractInc;
  Text[TextDescription].Text := Theme.Main.Description[Interaction];
  Text[TextDescriptionLong].Text := Theme.Main.DescriptionLong[Interaction];
  UpdateLCD;
  Light.LightOne(1, 200);
end;

procedure TScreenMain.UpdateLCD;
begin
  case Interaction of
    0:  LCD.WriteText(2, '      sing      ');
    1:  LCD.WriteText(2, '     editor     ');
    2:  LCD.WriteText(2, '    options     ');
    3:  LCD.WriteText(2, '      exit      ');
  end
end;

procedure TScreenMain.SetAnimationProgress(Progress: real);
begin
  Static[0].Texture.ScaleW := Progress;
  Static[0].Texture.ScaleH := Progress;
end;
end.
