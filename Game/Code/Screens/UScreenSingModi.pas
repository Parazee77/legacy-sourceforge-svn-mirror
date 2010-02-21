unit UScreenSingModi;

interface

uses UMenu, UMusic, SDL, SysUtils, UFiles, UTime, USongs, UIni, ULog, UTexture, ULyrics,
  TextGL, gl, BASS, UThemes, ULCD, UScreenSing, ModiSDK, UVideo;

type
  TScreenSingModi = class(TScreenSing)
    protected
    //paused: boolean; //Pause Mod
    //PauseTime: Real;
    //NumEmptySentences: integer;
    public
      //TextTime:           integer;

      //StaticP1:           integer;
      //StaticP1ScoreBG:    integer;
      //TextP1:             integer;
      //TextP1Score:        integer;

      //StaticP2R:          integer;
      //StaticP2RScoreBG:   integer;
      //TextP2R:            integer;
      //TextP2RScore:       integer;

      //StaticP2M:          integer;
      //StaticP2MScoreBG:   integer;
      //TextP2M:            integer;
      //TextP2MScore:       integer;

      //StaticP3R:          integer;
      //StaticP3RScoreBG:   integer;
      //TextP3R:            integer;
      //TextP3RScore:       integer;

      //Tex_Background:     TTexture;
      //FadeOut:            boolean;
      //LyricMain:          TLyric;
      //LyricSub:           TLyric;
      Winner: Byte; //Who Wins
      PlayerInfo: TPlayerInfo;
      TeamInfo:   TTeamInfo;

      constructor Create; override;
      procedure onShow; override;
      //procedure onShowFinish; override;
      function ParseInput(PressedKey: Cardinal; ScanCode: byte; PressedDown: Boolean): Boolean; override;
      function Draw: boolean; override;
      procedure Finish; override;
      //procedure UpdateLCD;
      //procedure Pause; //Pause Mod(Toggles Pause)
  end;

//Procedured for Plugin
function LoadTex   (const Name, Typ: PChar): TsmallTexture; stdcall;
//function Translate (const Name: PChar): PChar; stdcall;
procedure Print (const Style, Size: Byte; const X, Y: Real; const Text: PChar); stdcall;       //Procedure to Print Text
function LoadSound  (const Name: PChar): Cardinal; stdcall;       //Procedure that loads a Custom Sound
procedure PlaySound (const Index: Cardinal); stdcall;       //Plays a Custom Sound

//Utilys
function ToSentences(Const Czeski: TCzesci): TSentences;

implementation
uses UGraphic, UPartyM2, UParty, UDraw, UMain, Classes, URecord, ULanguage, math, UDLLManager, USkins, UGraphicClasses;

// Method for input parsing. If False is returned, GetNextWindow
// should be checked to know the next window to load;
function TScreenSingModi.ParseInput(PressedKey: Cardinal; ScanCode: byte; PressedDown: Boolean): Boolean;
var
  I: integer;

begin
  Result := true;
  If (PressedDown) Then
  begin // Key Down
    case PressedKey of
      SDLK_ESCAPE,
      SDLK_BACKSPACE :
        begin
          if ScreenSong.PartyMedley then
          begin
            PlaylistMedley.CurrentMedleySong:=PlaylistMedley.NumMedleySongs+1;
            Finish;
            Music.PlayBack;

            for I := 0 to PlayersPlay-1 do    //TODO: leave all this?
            begin
              Player[I].ScoreTotalI := PlaylistMedley.Stats[Length(PlaylistMedley.Stats)-1].Player[I].ScoreTotalI;
              if(ScreenSong.Mode=smChallenge) then
                TeamInfo.TeamInfo[I].Score:=Player[I].ScoreTotalI;
            end;

            {if ScreenSong.Mode=smChallenge then
            begin
              PartySessionM2.Teams:=TeamInfo;
              PartySessionM2.EndRound;
            end;}

            if ScreenSong.Mode = smChallenge then
              FadeTo(@ScreenScore)
            else
              FadeTo(@ScreenPartyScore);

          end else
          begin
            Finish;
            Music.PlayBack;

            if (ScreenSong.Mode=smParty) then
              FadeTo(@ScreenPartyScore)
            else
              FadeTo(@ScreenScore);
          end;
        end;

      else
        Result := inherited ParseInput(PressedKey, ScanCode, PressedDown);
    end;
  end;
end;

constructor TScreenSingModi.Create;
begin
  inherited Create;

end;

function ToSentences(Const Czeski: TCzesci): TSentences;
var
  I, J: Integer;
begin
  Result.Akt := Czeski.Akt;
  Result.High := Czeski.High;
  Result.Ilosc := Czeski.Ilosc;
  Result.Resolution := Czeski.Resolution;
  Result.NotesGAP := Czeski.NotesGAP;
  Result.TotalLength := Czeski.Wartosc;

  SetLength(Result.Sentence, Length(Czeski.Czesc));
  for I := low(Result.Sentence) to high(Result.Sentence) do
  begin
    Result.Sentence[I].Start := Czeski.Czesc[I].Start;
    Result.Sentence[I].StartNote := Czeski.Czesc[I].StartNote;
    Result.Sentence[I].Lyric := Czeski.Czesc[I].Lyric;
    Result.Sentence[I].LyricWidth := Czeski.Czesc[I].LyricWidth;
    Result.Sentence[I].Koniec := Czeski.Czesc[I].Koniec;
    Result.Sentence[I].BaseNote := Czeski.Czesc[I].BaseNote;
    Result.Sentence[I].HighNote := Czeski.Czesc[I].HighNut;
    Result.Sentence[I].IlNut := Czeski.Czesc[I].IlNut;
    Result.Sentence[I].TotalNotes := Czeski.Czesc[I].TotalNotes;

    SetLength(Result.Sentence[I].Note, Length(Czeski.Czesc[I].Nuta));
    for J := low(Result.Sentence[I].Note) to high(Result.Sentence[I].Note) do
    begin
      Result.Sentence[I].Note[J].Color := Czeski.Czesc[I].Nuta[J].Color;
      Result.Sentence[I].Note[J].Start := Czeski.Czesc[I].Nuta[J].Start;
      Result.Sentence[I].Note[J].Length := Czeski.Czesc[I].Nuta[J].Dlugosc;
      Result.Sentence[I].Note[J].Ton := Czeski.Czesc[I].Nuta[J].Ton;
      Result.Sentence[I].Note[J].TonGamy := Czeski.Czesc[I].Nuta[J].TonGamy;
      //Result.Sentence[I].Note[J].Text := Czeski.Czesc[I].Nuta[J].Tekst;
      Result.Sentence[I].Note[J].FreeStyle := Czeski.Czesc[I].Nuta[J].FreeStyle;
      Result.Sentence[I].Note[J].Typ := Czeski.Czesc[I].Nuta[J].Wartosc;
    end;
  end;
end;

procedure TScreenSingModi.onShow;
var
  I: Integer;
begin
  PlayersPlay := TeamInfo.NumTeams;

  if DLLMan.Selected.LoadSong then //Start with Song
  begin
    inherited;
  end
  else //Start Without Song
  begin
    Music.CaptureStart;
  end;

//Set Playerinfo
  PlayerInfo.NumPlayers := PlayersPlay;
  for I := 0 to PlayerInfo.NumPlayers-1 do
  begin
    if (ScreenSong.Mode=smChallenge) then
      Ini.Name[I] := TeamInfo.TeamInfo[I].Playerinfo[TeamInfo.TeamInfo[I].CurPlayer].Name;
    PlayerInfo.Playerinfo[I].Name := PChar(Ini.Name[I]);
    PlayerInfo.Playerinfo[I].Score:=  0;
    PlayerInfo.Playerinfo[I].Bar :=  50;
    PlayerInfo.Playerinfo[I].Enabled := True;
  end;

  for I := PlayerInfo.NumPlayers to high(PlayerInfo.Playerinfo) do
  begin
    PlayerInfo.Playerinfo[I].Score:=  0;
    PlayerInfo.Playerinfo[I].Bar :=  0;
    PlayerInfo.Playerinfo[I].Enabled := False;
  end;

  Case PlayersPlay of
    1: begin
      PlayerInfo.Playerinfo[0].PosX := Static[StaticP1ScoreBG].Texture.X;
      PlayerInfo.Playerinfo[0].PosY := Static[StaticP1ScoreBG].Texture.Y + Static[StaticP1ScoreBG].Texture.H;
    end;
    2,4: begin
      PlayerInfo.Playerinfo[0].PosX := Static[StaticP1TwoPScoreBG].Texture.X;
      PlayerInfo.Playerinfo[0].PosY := Static[StaticP1TwoPScoreBG].Texture.Y + Static[StaticP1TwoPScoreBG].Texture.H;
      PlayerInfo.Playerinfo[2].PosX := Static[StaticP1TwoPScoreBG].Texture.X;
      PlayerInfo.Playerinfo[2].PosY := Static[StaticP1TwoPScoreBG].Texture.Y + Static[StaticP1TwoPScoreBG].Texture.H;
      PlayerInfo.Playerinfo[1].PosX := Static[StaticP2RScoreBG].Texture.X;
      PlayerInfo.Playerinfo[1].PosY := Static[StaticP2RScoreBG].Texture.Y + Static[StaticP2RScoreBG].Texture.H;
      PlayerInfo.Playerinfo[3].PosX := Static[StaticP2RScoreBG].Texture.X;
      PlayerInfo.Playerinfo[3].PosY := Static[StaticP2RScoreBG].Texture.Y + Static[StaticP2RScoreBG].Texture.H;
    end;
    3,6: begin
      PlayerInfo.Playerinfo[0].PosX := Static[StaticP1ThreePScoreBG].Texture.X;
      PlayerInfo.Playerinfo[0].PosY := Static[StaticP1ThreePScoreBG].Texture.Y + Static[StaticP1ThreePScoreBG].Texture.H;
      PlayerInfo.Playerinfo[3].PosX := Static[StaticP1ThreePScoreBG].Texture.X;
      PlayerInfo.Playerinfo[3].PosY := Static[StaticP1ThreePScoreBG].Texture.Y + Static[StaticP1ThreePScoreBG].Texture.H;
      PlayerInfo.Playerinfo[1].PosX := Static[StaticP2MScoreBG].Texture.X;
      PlayerInfo.Playerinfo[1].PosY := Static[StaticP2MScoreBG].Texture.Y + Static[StaticP2MScoreBG].Texture.H;
      PlayerInfo.Playerinfo[4].PosX := Static[StaticP2MScoreBG].Texture.X;
      PlayerInfo.Playerinfo[4].PosY := Static[StaticP2MScoreBG].Texture.Y + Static[StaticP2MScoreBG].Texture.H;
      PlayerInfo.Playerinfo[2].PosX := Static[StaticP3RScoreBG].Texture.X;
      PlayerInfo.Playerinfo[2].PosY := Static[StaticP3RScoreBG].Texture.Y + Static[StaticP3RScoreBG].Texture.H;
      PlayerInfo.Playerinfo[5].PosX := Static[StaticP3RScoreBG].Texture.X;
      PlayerInfo.Playerinfo[5].PosY := Static[StaticP3RScoreBG].Texture.Y + Static[StaticP3RScoreBG].Texture.H;
    end;
  end;

  // play music (I)
  //Music.CaptureStart;
  //Music.MoveTo(AktSong.Start);

  //Init Plugin
  if not DLLMan.PluginInit(TeamInfo, PlayerInfo, ToSentences(Czesci[0]), LoadTex, Print, LoadSound, PlaySound) then
  begin
    //Fehler
    Log.LogError('Could not Init Plugin');
    Halt;
  end;

  // Set Background (Little Workaround, maybe change sometime)
  if (DLLMan.Selected.LoadBack) AND (DLLMan.Selected.LoadSong) then
    ScreenSing.Tex_Background := Tex_Background;

  Winner := 0;

  //Set Score Visibility
  if PlayersPlay = 1 then begin
    Text[TextP1Score].Visible := DLLMan.Selected.ShowScore;
    Static[StaticP1ScoreBG].Visible := DLLMan.Selected.ShowScore;
  end;

  if (PlayersPlay = 2) OR (PlayersPlay = 4) then begin
    Text[TextP1TwoPScore].Visible := DLLMan.Selected.ShowScore;
    Static[StaticP1TwoPScoreBG].Visible := DLLMan.Selected.ShowScore;

    Text[TextP2RScore].Visible := DLLMan.Selected.ShowScore;
    Static[StaticP2RScoreBG].Visible := DLLMan.Selected.ShowScore;
  end;

  if (PlayersPlay = 3) OR (PlayersPlay = 6) then begin
    Text[TextP1ThreePScore].Visible := DLLMan.Selected.ShowScore;
    Static[StaticP1ThreePScoreBG].Visible := DLLMan.Selected.ShowScore;

    Text[TextP2MScore].Visible := DLLMan.Selected.ShowScore;
    Static[StaticP2MScoreBG].Visible := DLLMan.Selected.ShowScore;

    Text[TextP3RScore].Visible := DLLMan.Selected.ShowScore;
    Static[StaticP3RScoreBG].Visible := DLLMan.Selected.ShowScore;
  end;
end;

function TScreenSingModi.Draw: boolean;
var
  Min:    integer;
  Sec:    integer;
  Tekst:  string;
  S, I:      integer;
  T:      integer;
  lastLine, LastWord: integer;
  medley_end:             boolean;
  medley_start_applause:  boolean;
  CurTime:  real;
begin
  //Aspect
  if AspectHandler.changed and (Czas.Teraz>AspectHandler.change_time + 3) then
  begin
    AspectHandler.changed:=false;
    Text[VideoAspectText].Visible := false;
    Static[VideoAspectStatic].Visible := false;
  end;

  // Set Background (Little Workaround, maybe change sometime)
  if (DLLMan.Selected.LoadBack) AND (DLLMan.Selected.LoadSong) then
    ScreenSing.Tex_Background := Tex_Background;
    
//Set Playerinfo
  PlayerInfo.NumPlayers := PlayersPlay;
  for I := 0 to PlayerInfo.NumPlayers-1 do
  begin
    PlayerInfo.Playerinfo[I].Name := PChar(Player[I].Name);
    if PlayerInfo.Playerinfo[I].Enabled then
    begin
      if (Player[I].ScoreTotalI<=10000) then
        PlayerInfo.Playerinfo[I].Score:=  Player[I].ScoreTotalI;
      PlayerInfo.Playerinfo[I].Bar :=  Player[I].ScorePercent;
    end;
  end;

//Show Score
if DLLMan.Selected.ShowScore then
begin
  //ScoreBG Mod
  // set player colors
  if PlayersPlay = 4 then begin
    if ScreenAct = 1 then begin
      LoadColor(Static[StaticP1TwoP].Texture.ColR, Static[StaticP1TwoP].Texture.ColG,
      Static[StaticP1TwoP].Texture.ColB, 'P1Dark');
      LoadColor(Static[StaticP2R].Texture.ColR, Static[StaticP2R].Texture.ColG,
      Static[StaticP2R].Texture.ColB, 'P2Dark');



      LoadColor(Static[StaticP1TwoPScoreBG].Texture.ColR, Static[StaticP1TwoPScoreBG].Texture.ColG,
      Static[StaticP1TwoPScoreBG].Texture.ColB, 'P1Dark');
      LoadColor(Static[StaticP2RScoreBG].Texture.ColR, Static[StaticP2RScoreBG].Texture.ColG,
      Static[StaticP2RScoreBG].Texture.ColB, 'P2Dark');



    end;
    if ScreenAct = 2 then begin
      LoadColor(Static[StaticP1TwoP].Texture.ColR, Static[StaticP1TwoP].Texture.ColG,
        Static[StaticP1TwoP].Texture.ColB, 'P3Dark');
      LoadColor(Static[StaticP2R].Texture.ColR, Static[StaticP2R].Texture.ColG,
        Static[StaticP2R].Texture.ColB, 'P4Dark');



      LoadColor(Static[StaticP1TwoPScoreBG].Texture.ColR, Static[StaticP1TwoPScoreBG].Texture.ColG,
        Static[StaticP1TwoPScoreBG].Texture.ColB, 'P3Dark');
      LoadColor(Static[StaticP2RScoreBG].Texture.ColR, Static[StaticP2RScoreBG].Texture.ColG,
        Static[StaticP2RScoreBG].Texture.ColB, 'P4Dark');



     end;
  end;

  if PlayersPlay = 6 then begin
    if ScreenAct = 1 then begin
      LoadColor(Static[StaticP1ThreeP].Texture.ColR, Static[StaticP1ThreeP].Texture.ColG,
        Static[StaticP1ThreeP].Texture.ColB, 'P1Dark');
      LoadColor(Static[StaticP2M].Texture.ColR, Static[StaticP2M].Texture.ColG,
        Static[StaticP2R].Texture.ColB, 'P2Dark');
      LoadColor(Static[StaticP3R].Texture.ColR, Static[StaticP3R].Texture.ColG,
        Static[StaticP3R].Texture.ColB, 'P3Dark');



      LoadColor(Static[StaticP1ThreePScoreBG].Texture.ColR, Static[StaticP1ThreePScoreBG].Texture.ColG,
        Static[StaticP1ThreePScoreBG].Texture.ColB, 'P1Dark');
      LoadColor(Static[StaticP2MScoreBG].Texture.ColR, Static[StaticP2MScoreBG].Texture.ColG,
        Static[StaticP2RScoreBG].Texture.ColB, 'P2Dark');
      LoadColor(Static[StaticP3RScoreBG].Texture.ColR, Static[StaticP3RScoreBG].Texture.ColG,
        Static[StaticP3RScoreBG].Texture.ColB, 'P3Dark');



    end;
    if ScreenAct = 2 then begin
      LoadColor(Static[StaticP1ThreeP].Texture.ColR, Static[StaticP1ThreeP].Texture.ColG,
        Static[StaticP1ThreeP].Texture.ColB, 'P4Dark');
      LoadColor(Static[StaticP2M].Texture.ColR, Static[StaticP2M].Texture.ColG,
        Static[StaticP2R].Texture.ColB, 'P5Dark');
      LoadColor(Static[StaticP3R].Texture.ColR, Static[StaticP3R].Texture.ColG,
        Static[StaticP3R].Texture.ColB, 'P6Dark');




      LoadColor(Static[StaticP1ThreePScoreBG].Texture.ColR, Static[StaticP1ThreePScoreBG].Texture.ColG,
        Static[StaticP1ThreePScoreBG].Texture.ColB, 'P4Dark');
      LoadColor(Static[StaticP2MScoreBG].Texture.ColR, Static[StaticP2MScoreBG].Texture.ColG,
        Static[StaticP2RScoreBG].Texture.ColB, 'P5Dark');
      LoadColor(Static[StaticP3RScoreBG].Texture.ColR, Static[StaticP3RScoreBG].Texture.ColG,
        Static[StaticP3RScoreBG].Texture.ColB, 'P6Dark');




    end;
  end;
  //end ScoreBG Mod

// set player names (for 2 screens and only Singstar skin)
  if ScreenAct = 1 then begin
    Text[TextP1].Text       := 'P1';
    Text[TextP1TwoP].Text   := 'P1'; // added for ps3 skin
    Text[TextP1ThreeP].Text := 'P1'; // added for ps3 skin
    Text[TextP2R].Text      := 'P2';
    Text[TextP2M].Text      := 'P2';
    Text[TextP3R].Text      := 'P3';
  end;

  if ScreenAct = 2 then begin
    case PlayersPlay of
      4:  begin
            Text[TextP1TwoP].Text := 'P3';
            Text[TextP2R].Text := 'P4';
          end;
      6:  begin
            Text[TextP1ThreeP].Text := 'P4';
            Text[TextP2M].Text := 'P5';
            Text[TextP3R].Text := 'P6';
          end;
    end; // case
  end; // if


  // stereo   <- and where iss P2M? or P3?
  Static[StaticP1].Texture.X := Static[StaticP1].Texture.X + 10*ScreenX;
  Static[StaticP1ScoreBG].Texture.X := Static[StaticP1ScoreBG].Texture.X + 10*ScreenX;

  Text[TextP1].X := Text[TextP1].X + 10*ScreenX;
  Text[TextP1Score].X := Text[TextP1Score].X + 10*ScreenX;

  Static[StaticP2R].Texture.X := Static[StaticP2R].Texture.X + 10*ScreenX;
  Static[StaticP2RScoreBG].Texture.X := Static[StaticP2RScoreBG].Texture.X + 10*ScreenX;

  Text[TextP2R].X := Text[TextP2R].X + 10*ScreenX;
  Text[TextP2RScore].X := Text[TextP2RScore].X + 10*ScreenX;

  // .. and scores
  if PlayersPlay = 1 then begin
    Tekst := IntToStr(Player[0].ScoreTotalI);
    while Length(Tekst) < 5 do Tekst := '0' + Tekst;
    Text[TextP1Score].Text := Tekst;
  end;

  if PlayersPlay = 2 then begin
    Tekst := IntToStr(Player[0].ScoreTotalI);
    while Length(Tekst) < 5 do Tekst := '0' + Tekst;
    Text[TextP1TwoPScore].Text := Tekst;

    Tekst := IntToStr(Player[1].ScoreTotalI);
    while Length(Tekst) < 5 do Tekst := '0' + Tekst;
    Text[TextP2RScore].Text := Tekst;
  end;

  if PlayersPlay = 3 then begin
    Tekst := IntToStr(Player[0].ScoreTotalI);
    while Length(Tekst) < 5 do Tekst := '0' + Tekst;
    Text[TextP1ThreePScore].Text := Tekst;

    Tekst := IntToStr(Player[1].ScoreTotalI);
    while Length(Tekst) < 5 do Tekst := '0' + Tekst;
    Text[TextP2MScore].Text := Tekst;

    Tekst := IntToStr(Player[2].ScoreTotalI);
    while Length(Tekst) < 5 do Tekst := '0' + Tekst;
    Text[TextP3RScore].Text := Tekst;
  end;

  if PlayersPlay = 4 then begin
    if ScreenAct = 1 then begin
      Tekst := IntToStr(Player[0].ScoreTotalI);
      while Length(Tekst) < 5 do Tekst := '0' + Tekst;
      Text[TextP1TwoPScore].Text := Tekst;

      Tekst := IntToStr(Player[1].ScoreTotalI);
      while Length(Tekst) < 5 do Tekst := '0' + Tekst;
      Text[TextP2RScore].Text := Tekst;
    end;
    if ScreenAct = 2 then begin
      Tekst := IntToStr(Player[2].ScoreTotalI);
      while Length(Tekst) < 5 do Tekst := '0' + Tekst;
      Text[TextP1TwoPScore].Text := Tekst;

      Tekst := IntToStr(Player[3].ScoreTotalI);
      while Length(Tekst) < 5 do Tekst := '0' + Tekst;
      Text[TextP2RScore].Text := Tekst;
    end;
  end;

  if PlayersPlay = 6 then begin
    if ScreenAct = 1 then begin
      Tekst := IntToStr(Player[0].ScoreTotalI);
      while Length(Tekst) < 5 do Tekst := '0' + Tekst;
      Text[TextP1ThreePScore].Text := Tekst;

      Tekst := IntToStr(Player[1].ScoreTotalI);
      while Length(Tekst) < 5 do Tekst := '0' + Tekst;
      Text[TextP2MScore].Text := Tekst;

      Tekst := IntToStr(Player[2].ScoreTotalI);
      while Length(Tekst) < 5 do Tekst := '0' + Tekst;
      Text[TextP3RScore].Text := Tekst;
    end;
    if ScreenAct = 2 then begin
      Tekst := IntToStr(Player[3].ScoreTotalI);
      while Length(Tekst) < 5 do Tekst := '0' + Tekst;
      Text[TextP1ThreePScore].Text := Tekst;

      Tekst := IntToStr(Player[4].ScoreTotalI);
      while Length(Tekst) < 5 do Tekst := '0' + Tekst;
      Text[TextP2MScore].Text := Tekst;

      Tekst := IntToStr(Player[5].ScoreTotalI);
      while Length(Tekst) < 5 do Tekst := '0' + Tekst;
      Text[TextP3RScore].Text := Tekst;
    end;
  end;

end; //ShowScore

  for S := 1 to 1 do
    Static[S].Texture.X := Static[S].Texture.X + 10*ScreenX;

  for T := 0 to 1 do
    Text[T].X := Text[T].X + 10*ScreenX;

if DLLMan.Selected.LoadSong then
begin
  // update static menu with time ...
  CurTime := Czas.Razem - Czas.Teraz;

  // update static menu with time ...
  if ScreenSong.PartyMedley then
    CurTime := MedleyEnd - Czas.Teraz
  else
    CurTime := Czas.Razem - Czas.Teraz ;

  Min := Round(CurTime) div 60;
  Sec := Round(CurTime) mod 60;
  Text[TextTimeText].Text := '';
  if Min < 10 then Text[TextTimeText].Text := '0';
  Text[TextTimeText].Text := Text[TextTimeText].Text + IntToStr(Min) + ':';

  if Sec < 10 then Text[TextTimeText].Text := Text[TextTimeText].Text + '0';
  Text[TextTimeText].Text := Text[TextTimeText].Text + IntToStr(Sec);
end;

  lastLine := Length(Czesci[0].Czesc)-1;
  lastWord := Length(Czesci[0].Czesc[lastLine].Nuta)-1;
  if (Czas.AktBeat>(Czesci[0].Czesc[lastLine].Nuta[lastWord].Start+
    Czesci[0].Czesc[lastLine].Nuta[lastWord].Dlugosc)) then
    ScreenSong.SungToEnd := true
  else
    ScreenSong.SungToEnd := false;

  // for medley-mode:
  CurTime := Czas.Teraz;
  if ScreenSong.PartyMedley and (CurTime > MedleyEnd) then
    medley_end := true
  else
    medley_end := false;

  if ScreenSong.PartyMedley and (CurTime >
    GetTimeFromBeat(AktSong.Medley.EndBeat)) then
    medley_start_applause := true
  else
    medley_start_applause := false;

  // draw static menu (BG)
  DrawBG;

  //Draw Background
  if (DllMan.Selected.LoadSong) AND (DllMan.Selected.LoadBack) then
    SingDrawBackground;

  // update and draw movie
  if ShowFinish and AktSong.VideoLoaded AND DllMan.Selected.LoadVideo then
  begin
    acGetFrame(Czas.Teraz);
    acDrawGL(ScreenAct); // this only draws
  end;

  // draw static menu (FG)
  DrawFG;

  //Medley Countdown
  if ScreenSong.PartyMedley then
    DrawMedleyCountdown;

  if ShowFinish and DllMan.Selected.LoadSong then
  begin
    if (not Music.Finished) and (not medley_end or not ScreenSong.PartyMedley)
      and ((AktSong.Finish = 0) or (CurTime*1000 <= AktSong.Finish)) then
    begin
      //Pause Mod:
      if not Paused then
      begin
        Sing(Self);       // analyze song
        //Update Medley Stats
        if ScreenSong.PartyMedley and not FadeOut then
          UpdateMedleyStats(medley_start_applause);
      end;
    end else
    begin
      if not FadeOut then
      begin
        Finish;
        if not ScreenSong.PartyMedley then
        begin
          FadeOut := true;
          if (ScreenSong.Mode=smParty) then
            FadeTo(@ScreenPartyScore)
          else
            FadeTo(@ScreenScore);
        end;
      end;
    end;
  end;

  // draw custom items
  SingModiDraw(PlayerInfo);  // always draw

  //GoldenNoteStarsTwinkle Mod
  GoldenRec.SpawnRec;
  //GoldenNoteStarsTwinkle Mod

  //Update PlayerInfo
  for I := 0 to PlayerInfo.NumPlayers-1 do
  begin
    if PlayerInfo.Playerinfo[I].Enabled then
    begin
      PlayerInfo.Playerinfo[I].Bar :=  Player[I].ScorePercent;
      PlayerInfo.Playerinfo[I].Score := Player[I].ScoreTotalI;
    end;
  end;

  if ((ShowFinish) AND (NOT Paused)) then
  begin
    if not DLLMan.PluginDraw(Playerinfo, Czesci[0].Akt) then
    begin
      if not FadeOut then
      begin
        Finish;
        if not ScreenSong.PartyMedley then
        begin
          FadeOut := true;
          if (ScreenSong.Mode=smParty) then
            FadeTo(@ScreenPartyScore)
          else
            FadeTo(@ScreenScore);
        end;
      end;
    end;
  end;

  //Change PlayerInfo/Changeables
  for I := 0 to PlayerInfo.NumPlayers-1 do
  begin
    if (Player[I].ScoreTotalI <> PlayerInfo.Playerinfo[I].Score) then
    begin
      //Player[I].ScoreTotal   := Player[I].ScoreTotal + (PlayerInfo.Playerinfo[I].Score - Player[I].ScoreTotalI);
      Player[I].ScoreTotalI := PlayerInfo.Playerinfo[I].Score;
    end;
    if (PlayerInfo.Playerinfo[I].Bar <> Player[I].ScorePercent) then
      Player[I].ScorePercentTarget := PlayerInfo.Playerinfo[I].Bar;
  end;

  // back stereo
  Static[StaticP1].Texture.X := Static[StaticP1].Texture.X - 10*ScreenX;
  Static[StaticP1ScoreBG].Texture.X := Static[StaticP1ScoreBG].Texture.X - 10*ScreenX;

  Text[TextP1].X := Text[TextP1].X - 10*ScreenX;
  Text[TextP1Score].X := Text[TextP1Score].X - 10*ScreenX;


  Static[StaticP2R].Texture.X := Static[StaticP2R].Texture.X - 10*ScreenX;
  Static[StaticP2RScoreBG].Texture.X := Static[StaticP2RScoreBG].Texture.X - 10*ScreenX;

  Text[TextP2R].X := Text[TextP2R].X - 10*ScreenX;
  Text[TextP2RScore].X := Text[TextP2RScore].X - 10*ScreenX;


  for S := 1 to 1 do
    Static[S].Texture.X := Static[S].Texture.X - 10*ScreenX;

  for T := 0 to 1 do
    Text[T].X := Text[T].X - 10*ScreenX;

  //Aspect
  if AspectHandler.changed and (Czas.Teraz>AspectHandler.change_time + 3) then
  begin
    AspectHandler.changed:=false;
    Text[VideoAspectText].Visible := false;
    Static[VideoAspectStatic].Visible := false;
  end;

  //Medley
  if MedleyHandler.changed and (Czas.Teraz>MedleyHandler.change_time + AktSong.Medley.FadeIn_time) then
  begin
    MedleyHandler.changed:=false;
    Static[SongNameStatic].Visible := false;
    Text[SongNameText].Visible := false;
  end;

  if ((ScreenSong.Mode=smParty) and
    (DLLMan.Plugins[PartySession.Rounds[PartySession.CurRound].Plugin].Name='PLUGIN_HAUDENLUKAS_NAME')) or
    ((ScreenSong.Mode=smChallenge) and
    (DLLMan.Plugins[PartySessionM2.Rounds[PartySessionM2.CurRound].Plugin].Name='PLUGIN_HAUDENLUKAS_NAME')) then
  begin

  end;

end;

procedure TScreenSingModi.Finish;
begin
  inherited Finish;

  Winner := DllMan.PluginFinish(PlayerInfo);

  //Log.LogError('Winner: ' + InttoStr(Winner));

  //DLLMan.UnLoadPlugin;
end;

function LoadTex (const Name, Typ: PChar): TsmallTexture; stdcall;
var
  Texname, EXT: String;
  Tex: TTexture;
begin
  //Get texture Name
  TexName := Skin.GetTextureFileName(String(Name));
  //Get File Typ
  Ext := ExtractFileExt(TexName);
  if (uppercase(Ext) = '.JPG') then
    Ext := 'JPG'
  else
    Ext := 'BMP';

  Tex := Texture.LoadTexture(PChar(TexName),  PChar(Ext), Typ, 0);

  Result.TexNum := Tex.TexNum;
  Result.W := Tex.W;
  Result.H := Tex.H;
end;
{
function Translate (const Name: PChar): PChar; stdcall;
begin
  Result := PChar(Language.Translate(String(Name)));
end; }

procedure Print (const Style, Size: Byte; const X, Y: Real; const Text: PChar); stdcall;       //Procedure to Print Text
begin
  SetFontItalic ((Style and 128) = 128);
  SetFontStyle(Style and 7);
  SetFontSize(Size);
  SetFontPos (X, Y);
  glPrint (PChar(Language.Translate(String(Text))));
end;

function LoadSound  (const Name: PChar): Cardinal; stdcall;       //Procedure that loads a Custom Sound
begin
 Result := Music.LoadCustomSound(String(Name));
end;

procedure PlaySound (const Index: Cardinal); stdcall;       //Plays a Custom Sound
begin
  Music.PlayCustomSound(Index);
end;

end.