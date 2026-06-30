report 50114 "TEST_Sales Rep by Tender Type"
{
    Caption = 'POS Sales Report by Tender Type';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50114_POSSalesReportByTenderType.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        // เปลี่ยนมาใช้สอยลูปด้วยตาราง Integer หลอก ดึงจากหน่วยความจำชั่วคราว
        dataitem(ReportLoop; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));

            column(Name_ComInfo; ComInfo.Name)
            { }
            column(ShowDate; ShowDate)
            { }
            column(ShowTime; ShowTime)
            { }
            column(PeriodDate; PeriodDate)
            { }
            column(ReportFilterText; ReportFilterText)
            { }
            column(Store_No_TransSale; TmpTransPayEntry."Store No.")
            { }
            column(POS_Terminal_No_TransPayEntry; TmpTransPayEntry."POS Terminal No.")
            { }
            column(Tender_Type_TransPayEntry; TmpTransPayEntry."Tender Type")
            { }
            column(Description_TenderTypeTB; TenderDescription)
            { }
            column(Receipt_No_TransPayEntry; TmpTransPayEntry."Receipt No.")
            { }
            column(MarkChangeLine; MarkChangeLine)
            { }
            column(Date_TransPayEntry; Format(TmpTransPayEntry.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))
            { }
            column(TransType; TransType)
            { }
            column(CardNo; CardNo)
            { }
            column(ContactNo_MemberContactTB; MemberContactTB."Contact No.")
            { }
            column(Name_MemberContactTB; MemberContactTB.Name + ' ' + MemberContactTB."Name 2")
            { }
            column(Amount_Tendered_TransPayEntry; TmpTransPayEntry."Amount Tendered")
            { }

            trigger OnPreDataItem()
            begin
                // Setup ส่วนตัวกรองงวดวันที่เหมือนเดิม
                IF Choose1Filter THEN BEGIN
                    DateFilter := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                END
                ELSE
                    IF Choose2Filter THEN BEGIN
                        DateFilter := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    END;

                // เคลียร์ข้อมูลเก่าในถังเก็บชั่วคราว
                TmpTransPayEntry.Reset();
                TmpTransPayEntry.DeleteAll();
                Clear(TmpTenderTypeDesc);
                Clear(TmpMemberCard);
                // TmpTenderTypeDesc.Reset();
                // TmpTenderTypeDesc.DeleteAll();
                // TmpMemberCard.Reset();
                // TmpMemberCard.DeleteAll();

                // ตั้งค่าท่อรับข้อมูลให้กับ Query Object ตัวใหม่
                if DateFilter <> '' then
                    SalesTenderQry.SetFilter(Date_Filter, DateFilter);
                if StoreFilter <> '' then
                    SalesTenderQry.SetFilter(Store_Filter, StoreFilter);
                if POSTerminalFilter <> '' then
                    SalesTenderQry.SetFilter(POS_Terminal_Filter, POSTerminalFilter);

                if CashOnlyFilter then
                    SalesTenderQry.SetFilter(Tender_Type_Filter, '%1|%2', '1', '9')
                else if TenderTypeFilter <> '' then
                    SalesTenderQry.SetFilter(Tender_Type_Filter, TenderTypeFilter);

                if StaffFilter <> '' then
                    SalesTenderQry.SetFilter(Staff_Filter, StaffFilter);
                if ChangeLineFilter then
                    SalesTenderQry.SetRange(Change_Line_Filter, false);

                // ยิงคิวรีรวดเดียวแล้วยัดข้อมูลลงถัง Temp Table บนหน่วยความจำ
                if SalesTenderQry.Open() then begin
                    while SalesTenderQry.Read() do begin
                        TmpTransPayEntry.Init();
                        TmpTransPayEntry."Store No." := SalesTenderQry.Store_No_;
                        TmpTransPayEntry."POS Terminal No." := SalesTenderQry.POS_Terminal_No_;
                        TmpTransPayEntry."Transaction No." := SalesTenderQry.Transaction_No_;
                        TmpTransPayEntry."Line No." := SalesTenderQry.Line_No_;
                        TmpTransPayEntry."Tender Type" := SalesTenderQry.Tender_Type_;
                        TmpTransPayEntry."Receipt No." := SalesTenderQry.Receipt_No_;
                        TmpTransPayEntry.Date := SalesTenderQry.Date;
                        TmpTransPayEntry."Amount Tendered" := SalesTenderQry.Amount_Tendered;
                        TmpTransPayEntry."Change Line" := SalesTenderQry.Change_Line;
                        TmpTransPayEntry."Safe type" := SalesTenderQry.Safe_type;
                        TmpTransPayEntry.Insert();

                        // พักรายละเอียดของ Tender Type และเบอร์ Infocode ไว้ใน Temp คู่อื่นๆ
                        KeyText := SalesTenderQry.Store_No_ + '_' + SalesTenderQry.Tender_Type_;
                        if not TmpTenderTypeDesc.ContainsKey(KeyText) then begin
                            TmpTenderTypeDesc.Add(KeyText, SalesTenderQry.Tender_Description);
                            TmpTenderInfocode.Add(KeyText, SalesTenderQry.PLSPOS_Infocode_Card_No_);
                        end;

                        // พักข้อมูลเลขบัตรสมาชิกที่โยงมาจากหัวบิล
                        KeyTextHeader := SalesTenderQry.Store_No_ + '_' + SalesTenderQry.POS_Terminal_No_ + '_' + Format(SalesTenderQry.Transaction_No_);
                        if (SalesTenderQry.Member_Card_No_ <> '') and (not TmpMemberCard.ContainsKey(KeyTextHeader)) then begin
                            TmpMemberCard.Add(KeyTextHeader, SalesTenderQry.Member_Card_No_);
                        end;
                    end;
                    SalesTenderQry.Close();
                end;

                // ประกอบข้อความหัวรายงาน (Report Filter Text) เหมือนสูตรเดิมของคุณ
                IF (StoreFilter <> '') THEN ReportFilterText += 'Store No : ' + FORMAT(StoreFilter + ' ');
                if POSTerminalFilter <> '' then ReportFilterText += ' POS Terminal No. : ' + POSTerminalFilter;
                if TenderTypeFilter <> '' then ReportFilterText += ' Tender type : ' + TenderTypeFilter;
                if StaffFilter <> '' then ReportFilterText += ' Staff ID : ' + StaffFilter;
                if CashOnlyFilter then ReportFilterText += ' ยอดขายเงินสด';
                if ChangeLineFilter then ReportFilterText += ' ไม่แสดงเงินทอน';

                // ตรวจสอบเช็ค Pointer ถ้าไม่เจอบิลสักใบให้ยกเลิกลูปทิ้งทันที
                if TmpTransPayEntry.IsEmpty() then
                    CurrReport.Break()
                else
                    TmpTransPayEntry.FindSet();
            end;

            trigger OnAfterGetRecord()
            var
                CurrentMemberCard: Code[20];
                CurrentInfocode: Code[20];
            begin
                // วนลูป Integer เลื่อน Pointer ข้อมูล Temp ขยับไปเรื่อยๆ ทีนละบรรทัด
                if Number > 1 then begin
                    if TmpTransPayEntry.Next() = 0 then
                        CurrReport.Break();
                end;

                Clear(TransType);
                Clear(MemberShipCardTB);
                Clear(MemberContactTB);

                // 1. ตรวจสอบข้อมูลผู้ติดต่อสมาชิก (ดึงข้อมูลจาก Key บิลที่ Cache ไว้ในความจำ)
                KeyTextHeader := TmpTransPayEntry."Store No." + '_' + TmpTransPayEntry."POS Terminal No." + '_' + Format(TmpTransPayEntry."Transaction No.");
                if TmpMemberCard.ContainsKey(KeyTextHeader) then begin
                    CurrentMemberCard := TmpMemberCard.Get(KeyTextHeader);
                    if MemberShipCardTB.Get(CurrentMemberCard) then
                        if MemberContactTB.Get(MemberShipCardTB."Account No.", MemberShipCardTB."Contact No.") then;
                end;

                // 2. ดึงรายละเอียดคำอธิบายของ Tender Type ในลูป
                Clear(TenderDescription);
                Clear(CardNo);
                KeyText := TmpTransPayEntry."Store No." + '_' + TmpTransPayEntry."Tender Type";
                if TmpTenderTypeDesc.ContainsKey(KeyText) then begin
                    TenderDescription := TmpTenderTypeDesc.Get(KeyText);
                    CurrentInfocode := TmpTenderInfocode.Get(KeyText);

                    // 3. หากมีเงื่อนไข Infocode เลขที่บัตร ให้คิวรีเจาะดึงเฉพาะฟิลด์ Information ทันที
                    if CurrentInfocode <> '' then begin
                        Clear(TransInfoEntry);
                        TransInfoEntry.SetCurrentKey("Store No.", "POS Terminal No.", "Transaction No.", "Transaction Type", "Line No.");
                        TransInfoEntry.SetRange("Store No.", TmpTransPayEntry."Store No.");
                        TransInfoEntry.SetRange("POS Terminal No.", TmpTransPayEntry."POS Terminal No.");
                        TransInfoEntry.SetRange("Transaction No.", TmpTransPayEntry."Transaction No.");
                        TransInfoEntry.SetRange("Transaction Type", TransInfoEntry."Transaction Type"::"Payment Entry");
                        TransInfoEntry.SetRange("Line No.", TmpTransPayEntry."Line No.");
                        TransInfoEntry.SetRange(Infocode, CurrentInfocode);
                        TransInfoEntry.SetLoadFields(Information);
                        if TransInfoEntry.FindFirst() then
                            CardNo := CopyStr(TransInfoEntry.Information, 1, 4);
                    end;
                end;

                // 4. มาร์กเครื่องหมายสำหรับเงินทอนท้ายบรรทัด
                Clear(MarkChangeLine);
                if TmpTransPayEntry."Change Line" then
                    MarkChangeLine := 'เงินทอน';
                if TmpTransPayEntry."Safe type" <> TmpTransPayEntry."Safe type"::" " then
                    MarkChangeLine := Format(TmpTransPayEntry."Safe type");
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
                        field("POS Terminal :"; POSTerminalFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'POS Terminal :';
                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                Clear(POSTerminalTB);
                                if StoreFilter <> '' then
                                    POSTerminalTB.SetRange("Store No.", StoreFilter);
                                if POSTerminalTB.FindSet() then
                                    if Page.RunModal(Page::"LSC POS Terminal List", POSTerminalTB) = Action::LookupOK then
                                        POSTerminalFilter := POSTerminalTB."No.";
                            end;
                        }
                        field("ยอดขายเงินสด :"; CashOnlyFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'ยอดขายเงินสด :';
                        }
                        field("ไม่แสดงเงินทอน :"; ChangeLineFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'ไม่แสดงเงินทอน :';
                        }
                        field("Tender Type :"; TenderTypeFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = "LSC Tender Type".Code;
                            Caption = 'Tender Type :';
                        }
                        field("Staff ID :"; StaffFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = "LSC Staff".ID;
                            Caption = 'Staff ID :';
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
            SelectLatestVersion();
            FDateFilter := Today;
            Choose1Filter := false;
            Choose2Filter := true;
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
        MemberContactTB: Record "LSC Member Contact";
        MemberShipCardTB: Record "LSC Membership Card";
        TransInfoEntry: Record "LSC Trans. Infocode Entry";
        POSTerminalTB: Record "LSC POS Terminal";
        SalesTenderQry: Query "TEST_Sales By Tender Query";

        // ตัวแปร Temporary เก็บข้อมูล Memory เพื่อสปีดความเร็วรายงาน
        TmpTransPayEntry: Record "LSC Trans. Payment Entry" temporary;
        TmpTenderTypeDesc: Dictionary of [Text, Text];
        TmpTenderInfocode: Dictionary of [Text, Code[20]];
        TmpMemberCard: Dictionary of [Text, Code[20]];

        KeyText: Text;
        KeyTextHeader: Text;
        TenderDescription: Text[100];
        StoreFilter: Code[20];
        POSTerminalFilter: Code[20];
        TenderTypeFilter: Code[20];
        StaffFilter: Code[20];
        ShowTime: Text[50];
        ShowDate: Text[50];
        DateFilter: Text[100];
        TransType: Text[50];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        CardNo: Text[4];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        CashOnlyFilter: Boolean;
        ChangeLineFilter: Boolean;
        MarkChangeLine: Text[30];
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
}