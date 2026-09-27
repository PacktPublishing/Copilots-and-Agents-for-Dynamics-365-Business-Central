// ----------------------------------------------------------------------------
// Codeunit 98209 - Session change log
// Subscribes to OnBeforeModify of "Event Session" and writes one
// "CE Session Change" entry per changed aspect, so the attendee assistant can
// answer "has anything changed in my agenda?" from a log instead of
// comparing snapshots. It reads the stored record and compares it with Rec,
// because xRec is not reliable when Modify is called from code (demo
// actions, Chapter 6 cancel, agents). Only news is logged:
// - nothing while the session is still a Draft (that is planning, Chapter 3);
// - no room entry for the first assignment of a room (Room Planning Agent,
//   Chapter 6), only for a reassignment.
// ----------------------------------------------------------------------------
codeunit 98209 "CE Session Change Log"
{
    SingleInstance = true;

    var
        SuppressLogging: Boolean;

    [EventSubscriber(ObjectType::Table, Database::"Event Session", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifySession(var Rec: Record "Event Session"; var xRec: Record "Event Session"; RunTrigger: Boolean)
    var
        Stored: Record "Event Session";
        Changed: Boolean;
    begin
        if Rec.IsTemporary() or SuppressLogging then
            exit;
        if not Stored.Get(Rec."Code") then
            exit;
        if Stored.Status = Stored.Status::Draft then
            exit;

        if (Stored."Room Code" <> '') and (Rec."Room Code" <> Stored."Room Code") then begin
            LogChange(Rec, "CE Session Change Type"::Room, RoomName(Stored."Room Code"), RoomName(Rec."Room Code"));
            Changed := true;
        end;

        if (Rec."Date" <> Stored."Date") or (Rec."Start Time" <> Stored."Start Time") or (Rec."End Time" <> Stored."End Time") then begin
            LogChange(Rec, "CE Session Change Type"::Schedule, FormatSlot(Stored), FormatSlot(Rec));
            Changed := true;
        end;

        if Rec.Speaker1 <> Stored.Speaker1 then begin
            LogChange(Rec, "CE Session Change Type"::Speaker, Stored.Speaker1, Rec.Speaker1);
            Changed := true;
        end;

        if (Rec.Status <> Stored.Status) and (Rec.Status = Rec.Status::Cancelled) then begin
            LogChange(Rec, "CE Session Change Type"::Cancelled, Format(Stored.Status), Format(Rec.Status));
            Changed := true;
        end;

        // The record is written right after this event, so no Modify here.
        if Changed then
            Rec."Last Changed At" := CurrentDateTime();
    end;

    procedure SetSuppressLogging(NewValue: Boolean)
    begin
        SuppressLogging := NewValue;
    end;

    procedure AddNoteToLastChange(SessionCode: Code[20]; NoteText: Text)
    var
        SessionChange: Record "CE Session Change";
    begin
        SessionChange.SetCurrentKey("Changed At");
        SessionChange.SetRange("Session Code", SessionCode);
        if SessionChange.FindLast() then begin
            SessionChange.Note := CopyStr(NoteText, 1, MaxStrLen(SessionChange.Note));
            SessionChange.Modify(true);
        end;
    end;

    local procedure LogChange(Session: Record "Event Session"; ChangeType: Enum "CE Session Change Type"; OldValue: Text; NewValue: Text)
    var
        SessionChange: Record "CE Session Change";
    begin
        SessionChange.Init();
        SessionChange."Event Project No." := Session."Project Code";
        SessionChange."Session Code" := Session."Code";
        SessionChange."Change Type" := ChangeType;
        SessionChange."Old Value" := CopyStr(OldValue, 1, MaxStrLen(SessionChange."Old Value"));
        SessionChange."New Value" := CopyStr(NewValue, 1, MaxStrLen(SessionChange."New Value"));
        SessionChange."Changed At" := CurrentDateTime();
        SessionChange.Insert(true);
    end;

    local procedure RoomName(RoomCode: Code[20]): Text
    var
        Room: Record Room;
    begin
        if Room.Get(RoomCode) then
            exit(Room.Name);
        exit(RoomCode);
    end;

    local procedure FormatSlot(Session: Record "Event Session"): Text
    begin
        exit(Format(Session."Date", 0, '<Day,2>/<Month,2>') + ' ' +
             Format(Session."Start Time", 0, '<Hours24>:<Minutes,2>') + '-' +
             Format(Session."End Time", 0, '<Hours24>:<Minutes,2>'));
    end;
}
