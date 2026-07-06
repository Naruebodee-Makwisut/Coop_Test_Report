report 50111 "TEST_Sales Rep by Special Gr"
{
    Caption = 'POS Sales Rep by Special Group';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50111_POSSalesReportBySpecialGroup.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Item Special Groups"; "LSC Item Special Groups")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = Code;
            PrintOnlyIfDetail = true;
            column(Name_ComInfo; ComInfo.Name)
            { }
            column(ShowDate; ShowDate)
            { }
            column(ShowTime; ShowTime)
            { }
            column(DateHeader; DateHeader)
            { }
            column(Header_txt; Header_txt)
            { }
            column(Item_No_Caption; Item_No_CaptionLbl)
            { }
            column(Special_GroupCaption; Special_GroupCaptionLbl)
            { }
            column(DescriptionCaption; DescriptionCaptionLbl)
            { }
            column(Qty_Caption; Qty_CaptionLbl)
            { }
            column(TotalCaption; TotalCaptionLbl)
            { }
            column(Item_Special_Groups_Code; Code)
            { }
            column(Item_Special_Groups_Description; Description)
            { }
            column(Sale_LCYCaption; Sale_LCYCaptionLbl)
            { }
            dataitem("Item_Special Group Link"; "LSC Item/Special Group Link")
            {
                DataItemTableView = SORTING("Special Group Code", "Item No.");
                DataItemLink = "Special Group Code" = field(Code);
                PrintOnlyIfDetail = true;
                dataitem(Item; Item)
                {
                    DataItemTableView = sorting("No.");
                    DataItemLink = "No." = field("Item No.");

                    column(No_Item; "No.") { }
                    column(Description_Item; Description) { }
                    column(SaleQty; SaleQty) { }
                    column(SaleLCY; SaleLCY) { }

                    trigger OnAfterGetRecord()
                    begin
                        CLEAR(SaleQty);
                        CLEAR(SaleLCY);

                        TempItemSum.Reset();
                        TempItemSum.SetRange("No.", Item."No.");
                        if TempItemSum.FindFirst() then begin
                            SaleQty := -TempItemSum."Unit Price"; // ดึงค่า Qty ที่ฝากไว้
                            SaleLCY := -TempItemSum."Profit %";   // ดึงค่า Amount ที่ฝากไว้
                        end;

                        if not ShowZeroFilter then
                            if SaleQty = 0 then
                                CurrReport.Skip();
                    end;
                }
            }

            trigger OnPreDataItem()
            begin
                IF Choose1Filter THEN BEGIN
                    DateFilter := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    DateHeader := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                END
                ELSE
                    IF Choose2Filter THEN BEGIN
                        DateFilter := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        DateHeader := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    END;
                IF (StoreFilter <> '') THEN
                    Header_txt += 'Store No : ' + FORMAT(StoreFilter + ' ');
                IF ("Item Special Groups".GETFILTERS <> '') THEN
                    if Header_txt <> '' then
                        Header_txt += ' , ' + "Item Special Groups".GETFILTERS
                    else
                        Header_txt := CopyStr("Item Special Groups".GETFILTERS(), 1, 250);

                TempItemSum.Reset();
                TempItemSum.DeleteAll();

                if DateFilter <> '' then
                    POSSalesSumQry.SetFilter(Date_Filter, DateFilter);
                if StoreFilter <> '' then
                    POSSalesSumQry.SetRange(Store_Filter, StoreFilter);

                if POSSalesSumQry.Open() then begin
                    while POSSalesSumQry.Read() do begin
                        TempItemSum.Init();
                        TempItemSum."No." := POSSalesSumQry.Item_No_;
                        TempItemSum."Unit Price" := POSSalesSumQry.Sum_Quantity;
                        TempItemSum."Profit %" := POSSalesSumQry.Sum_Amount;
                        TempItemSum.Insert();
                    end;
                    POSSalesSumQry.Close();
                end;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group("Filter")
                {
                    group("Data Filter")
                    {
                        field("Store No. :"; StoreFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = "LSC Store"."No.";
                            Caption = 'Store No. :';
                            ToolTip = 'Specifies the Store No. to filter the report.';
                        }
                        field("Show Zero:"; ShowZeroFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'Show Zero:';
                            ToolTip = 'Specifies the Show Zero to filter the report.';
                        }
                    }
                    group("Date Filter 1")
                    {
                        field(Period; Choose1Filter)
                        {
                            ApplicationArea = All;
                            Caption = 'Period';
                            ToolTip = 'Specifies the Period to filter the report.';
                            trigger OnValidate()
                            begin
                                if Choose1Filter then
                                    Choose2Filter := false
                                else
                                    Choose2Filter := true;
                            end;
                        }
                        group("Period Date")
                        {
                            field("Start Date"; FromDateFilter)
                            {
                                ApplicationArea = All;
                                Editable = Choose1Filter;
                                Caption = 'Start Date';
                                ToolTip = 'Specifies the Start Date to filter the report.';
                            }

                            field("End Date"; TodateFilter)
                            {
                                ApplicationArea = All;
                                Editable = Choose1Filter;
                                Caption = 'End Date';
                                ToolTip = 'Specifies the End Date to filter the report.';
                            }
                        }
                    }
                    group("Date Filter 2")
                    {
                        field("At Date"; Choose2Filter)
                        {
                            ApplicationArea = All;
                            Caption = 'At Date';
                            ToolTip = 'Specifies the At Date to filter the report.';
                            trigger OnValidate()
                            begin
                                if Choose2Filter then
                                    Choose1Filter := false
                                else
                                    Choose1Filter := true;
                            end;
                        }
                        group("At Date filter")
                        {
                            field("Date"; FDateFilter)
                            {
                                ApplicationArea = All;
                                Editable = Choose2Filter;
                                Caption = 'Date';
                                ToolTip = 'Specifies the Date to filter the report.';
                            }

                        }
                    }
                }
            }
        }
        trigger OnOpenPage()
        begin
            FDateFilter := Today;
            Choose1Filter := false;
            Choose2Filter := true;
            ShowZeroFilter := true;
        end;

    }

    trigger OnPreReport()
    begin
        ComInfo.Get();
        ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
    end;

    var
        ComInfo: Record "Company Information";
        TempItemSum: Record Item temporary;
        // TransSales: Record "LSC Trans. Sales Entry";

        LSVIPRepFunction: Codeunit "PLSR_Report Function";

        POSSalesSumQry: Query "TEST_POS Sales Sum Query";

        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        ShowZeroFilter: Boolean;
        FDateFilter: Date;
        FromDateFilter: Date;
        TodateFilter: Date;
        SaleLCY: Decimal;
        SaleQty: Decimal;
        DateFilter: Text[100];
        DateHeader: Text[150];
        Header_txt: Text[250];
        ShowDate: Text[50];
        ShowTime: Text[50];
        StoreFilter: Code[20];
        DescriptionCaptionLbl: Label 'ชื่อสินค้า';
        Item_No_CaptionLbl: Label 'รหัสสินค้า';
        Qty_CaptionLbl: Label 'จำนวน';
        Sale_LCYCaptionLbl: Label 'ยอดขายสุทธิ (Inc. VAT)';
        Special_GroupCaptionLbl: Label 'Special Group';
        TotalCaptionLbl: Label 'Total';
}