codeunit 50104 "IncomingDocumentsExtension"
{
    var
        incomingDocument: Record "Incoming Document";
        incomingDocumentAtt: Record "Incoming Document Attachment";

    trigger OnRun()
    begin

    end;

    //MY METHOD

    procedure ImportDocumentAsJSON(document: Text) ReturnValue: Text
    var
        token: JsonToken;
        tokenAtt: JsonToken;
        documentParsed: JsonObject;
        attObj: JsonObject;
        attArray: JsonArray;
        att: JsonToken;
        docDescription: text;
        docStatusField: text;
        TempBlob: Record TempBlob temporary;
        //For Debug
        resp: text;
        respB: Boolean;
    begin
        // Process JSON

        if not documentParsed.ReadFrom(document) then
            Error('Invalid response, expected an JSON OBJECT as root object');


        //Inserting Document into table 130
        incomingDocument.Init();
        incomingDocument.Description := GetJsonToken(documentParsed, 'Description').AsValue.AsText;
        incomingDocument.CreateIncomingDocument(incomingDocument.Description, '');


        //Inserting attachment and linking to previous document inserted
        incomingDocumentAtt.Init();
        TempBlob.FromBase64String(GetJsonToken(documentParsed, 'MainAttachment').AsValue.AsText);
        incomingDocumentAtt.Content := TempBlob.Blob;
        incomingDocumentAtt."Incoming Document Entry No." := incomingDocument."Entry No.";
        incomingDocumentAtt.Type := incomingDocumentAtt.Type::Other;
        incomingDocumentAtt."Line No." := 10000;
        incomingDocumentAtt."Main Attachment" := True;
        documentParsed.Get('SupportingAttachments', tokenAtt);
        foreach att in tokenAtt.AsArray() do begin
            if att.IsObject() then begin
                attObj := att.AsObject();
                incomingDocumentAtt.Name := GetJsonToken(attObj, 'Name').AsValue.AsText;
                incomingDocumentAtt."File Extension" := GetJsonToken(attObj, 'File_Extension').AsValue.AsText;
            end;
        end;
        respB := incomingDocumentAtt.Insert();


        ReturnValue := StrSubstNo('Result: Was the item Inserted? %1. Document ID: %2', respB, incomingDocument."Entry No.");
    end;


    //BASIC CONVERTIONS FOR JSON
    procedure GetJsonToken(JsonObject: JsonObject; TokenKey: text) JsonToken: JsonToken;
    begin
        if not JsonObject.Get(TokenKey, JsonToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    procedure SelectJsonToken(JsonObject: JsonObject; Path: text) JsonToken: JsonToken;
    begin
        if not JsonObject.SelectToken(Path, JsonToken) then
            Error('Could not find a token with path %1', Path);
    end;
}
