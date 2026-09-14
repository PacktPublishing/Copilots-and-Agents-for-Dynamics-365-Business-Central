namespace CronusEvents.Conference;

// Custom API - sessions (read only).
// Used by session-browsing-by-track, speaker-lookup and session-rating-lookup.
page 98106 "CE Session API"
{
    PageType = API;
    Caption = 'session', Locked = true;
    APIPublisher = 'cronusEvents';
    APIGroup = 'conference';
    APIVersion = 'v1.0';
    EntityName = 'session';
    EntitySetName = 'sessions';
    SourceTable = "CE Conference Session";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'systemId', Locked = true;
                }
                field(sessionCode; Rec."Session Code")
                {
                    Caption = 'sessionCode', Locked = true;
                }
                field(title; Rec.Title)
                {
                    Caption = 'title', Locked = true;
                }
                field(track; Rec.Track)
                {
                    Caption = 'track', Locked = true;
                }
                field(speakerCode; Rec."Speaker Code")
                {
                    Caption = 'speakerCode', Locked = true;
                }
                field(speakerName; Rec."Speaker Name")
                {
                    Caption = 'speakerName', Locked = true;
                }
                field(startDateTime; Rec."Start Date Time")
                {
                    Caption = 'startDateTime', Locked = true;
                }
                field(endDateTime; Rec."End Date Time")
                {
                    Caption = 'endDateTime', Locked = true;
                }
                field(room; Rec.Room)
                {
                    Caption = 'room', Locked = true;
                }
                field(conferenceDay; Rec."Conference Day")
                {
                    Caption = 'conferenceDay', Locked = true;
                }
                field(abstract; Rec.Abstract)
                {
                    Caption = 'abstract', Locked = true;
                }
                field(averageRating; Rec."Average Rating")
                {
                    Caption = 'averageRating', Locked = true;
                }
                field(ratingsCount; Rec."Ratings Count")
                {
                    Caption = 'ratingsCount', Locked = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Speaker Name");
    end;
}
