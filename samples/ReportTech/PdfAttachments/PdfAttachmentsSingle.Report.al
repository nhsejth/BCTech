
//using System;

report 50954 PdfAttachmentsSingle
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = WordLayout;

    dataset
    {
        dataitem(DataItemName; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 10));

            column(ColumnName; DataItemName.Number)
            {

            }

            trigger OnAfterGetRecord()
            var
                myInt: Integer;
            begin
                // Add something to the E-invocing xml document
            end;
        }


    }

    requestpage
    {
        AboutTitle = 'Teaching tip title';
        AboutText = 'Teaching tip content';
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field("User Code"; UserCode)
                    {
                        ApplicationArea = All;
                    }
                    field("Admin Code"; AdminCode)
                    {
                        ApplicationArea = All;
                    }
                    field("Number of Attachments"; NumberOfAttachments)
                    {
                        ApplicationArea = All;
                    }
                    field("Number of Files to Append"; NumberOfFilesToAppend)
                    {
                        ApplicationArea = All;
                    }
                }
            }
        }

        actions
        {
            area(processing)
            {
                action(LayoutName)
                {

                }
            }
        }
    }

    rendering
    {
        layout(WordLayout)
        {
            Type = Word;
            LayoutFile = 'PdfAttachmentsSingle.docx';
        }
    }
    trigger OnInitReport()
    begin
        this.AdminCode := '';
        this.UserCode := '';
        this.NumberOfAttachments := 0;
        this.NumberOfFilesToAppend := 0;
    end;

    trigger OnPreReport()
    begin
        // Add your code here
        // Initialize the E-invoicing xml document if needed.        
        if CurrReport.TargetFormat = ReportFormat::PDF then begin
            // Add the legal documents to append to the report
            clear(ReportRenderingCompleteHandlerInstance);
        end;
    end;

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    begin
        OnRenderingCompleteJsonProc(RenderingPayload);
    end;

    local procedure CreatePdfFile(Filename: Text; Content: Text) FilePath: Text
    var
        DocPro: DotNet WordHandler;
        File: File;
        OutStream: OutStream;
    begin
        FilePath := System.TemporaryPath + Filename;
        FilePath := DocPro.CreateSamplePdfDocument(FilePath, Content)
    end;

    local procedure CreateXmlFile(Filename: Text; Content: Text) FilePath: Text
    var
        FileObject: File;
        OutStream: OutStream;
    begin
        FilePath := System.TemporaryPath + Filename;
        FileObject.TextMode := true;
        FileObject.Create(FilePath);
        FileObject.CreateOutStream(OutStream);
        OutStream.WriteText('<?xml version="1.0" encoding="utf-8" standalone="yes"?>');
        OutStream.WriteText('<root><test>');
        OutStream.WriteText(Content);
        OutStream.WriteText('</test></root>');
        FileObject.Close();
    end;

    local procedure SaveJson(var RenderingPayload: JsonObject)
    var
        File: File;
        OutStream: OutStream;
        JsonText: Text;
        PdfAttachmentManager: Codeunit PdfHelper;
    begin
        File.Create(PdfAttachmentManager.GetOutputPath() + '\RenderingPayload.json');
        File.CreateOutStream(OutStream);
        RenderingPayload.WriteTo(JsonText);
        OutStream.WriteText(JsonText);
        File.Close();
    end;

    //[NonDebuggable]
    procedure OnRenderingCompleteJsonProc(var RenderingPayload: JsonObject)
    var
        UserCode: SecretText;
        AdminCode: SecretText;
        i: Integer;
        FileName: Text;
        Name: Text;
        MimeType: Text;
        Description: Text;
        DataType: enum PdfAttachmentDataRelationShip;
    begin
        if CurrReport.TargetFormat <> ReportFormat::PDF then
            exit;

        // Configure the rendering complete handler
        Name := 'factur-x.xml';
        FileName := CreateXmlFile(Name, 'This is my xml file');
        DataType := PdfAttachmentDataRelationShip::Alternative;
        MimeType := 'text/xml';
        Description := 'This is the e-invoicing xml document';

        ReportRenderingCompleteHandlerInstance.AddAttachment(Name, DataType, MimeType, FileName, Description, true);

        // Assign the codeunit to the interface which is consumed by the platform.
        // Platform will act like the ServerSideMock codeunit and call the methods on the interface.
        RenderingPayload := ReportRenderingCompleteHandlerInstance.ToJson(RenderingPayload);
        SaveJson(RenderingPayload);
    end;

    var
        ReportRenderingCompleteHandlerInstance: Codeunit ReportRenderingCompleteHandler;
        UserCode: Text;
        AdminCode: Text;
        NumberOfAttachments: Integer;
        NumberOfFilesToAppend: Integer;
}
