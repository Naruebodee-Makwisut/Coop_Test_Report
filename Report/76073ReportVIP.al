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

                        // >>> ดึงข้อมูลจาก TmpItemSum แทน <<<
                        TmpItemSum.Reset();
                        TmpItemSum.SetRange("No.", Item."No.");
                        if TmpItemSum.FindFirst() then begin
                            SaleQty := -TmpItemSum."Unit Price"; // ดึงค่า Qty ที่ฝากไว้
                            SaleLCY := -TmpItemSum."Profit %";   // ดึงค่า Amount ที่ฝากไว้
                        end;

                        if not ShowZeroFilter then
                            if SaleQty = 0 then
                                CurrReport.Skip();
                    end;
                }
            }

            trigger OnPreDataItem()
            begin
                // --- โค้ดจัดการ DateFilter และ Header_txt เดิมของคุณคงไว้ด้านบน ---
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
                // -------------------------------------------------------------

                // >>> แก้ไขโค้ดส่วน QUERY ใน OnPreDataItem <<<
                TmpItemSum.Reset();
                TmpItemSum.DeleteAll();

                if DateFilter <> '' then
                    POSSalesSumQry.SetFilter(Date_Filter, DateFilter);
                if StoreFilter <> '' then
                    POSSalesSumQry.SetRange(Store_Filter, StoreFilter);

                if POSSalesSumQry.Open() then begin
                    while POSSalesSumQry.Read() do begin
                        TmpItemSum.Init();
                        TmpItemSum."No." := POSSalesSumQry.Item_No_;
                        // ใช้ฟิลด์ Decimal ที่มีอยู่ในตาราง Item เป็นที่พักข้อมูลชั่วคราว
                        TmpItemSum."Unit Price" := POSSalesSumQry.Sum_Quantity;    // พักค่า Qty
                        TmpItemSum."Profit %" := POSSalesSumQry.Sum_Amount;       // พักค่า Amount
                        TmpItemSum.Insert();
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
                        }
                        field("Show Zero:"; ShowZeroFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'Show Zero:';
                        }
                    }
                    group("Date Filter 1")
                    {
                        field(Period; Choose1Filter)
                        {
                            ApplicationArea = All;
                            Caption = 'Period';
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
                            }

                            field("End Date"; TodateFilter)
                            {
                                ApplicationArea = All;
                                Editable = Choose1Filter;
                                Caption = 'End Date';
                            }
                        }
                    }
                    group("Date Filter 2")
                    {
                        field("At Date"; Choose2Filter)
                        {
                            ApplicationArea = All;
                            Caption = 'At Date';
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
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        TransSales: Record "LSC Trans. Sales Entry";
        POSSalesSumQry: Query "TEST_POS Sales Sum Query";
        TmpItemSum: Record Item temporary;
        ShowTime: Text[50];
        ShowDate: Text[50];
        DateFilter: Text[100];
        DateHeader: Text[150];
        Header_txt: Text[250];
        StoreFilter: Code[20];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        ShowZeroFilter: Boolean;
        SaleQty: Decimal;
        SaleLCY: Decimal;
        Sale_LCYCaptionLbl: Label 'ยอดขายสุทธิ (Inc. VAT)';
        Qty_CaptionLbl: Label 'จำนวน';
        DescriptionCaptionLbl: Label 'ชื่อสินค้า';
        Item_No_CaptionLbl: Label 'รหัสสินค้า';
        Special_GroupCaptionLbl: Label 'Special Group';
        TotalCaptionLbl: Label 'Total';
}