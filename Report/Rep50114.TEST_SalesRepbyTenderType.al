report 50114 "TEST_Sales Rep by Tender Type"
{
    Caption = 'POS Sales Report by Tender Type';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50114_POSSalesReportByTenderType.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
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
            column(Store_No_TransSale; TempTransPayEntry."Store No.")
            { }
            column(POS_Terminal_No_TransPayEntry; TempTransPayEntry."POS Terminal No.")
            { }
            column(Tender_Type_TransPayEntry; TempTransPayEntry."Tender Type")
            { }
            column(Description_TenderTypeTB; TenderDescription)
            { }
            column(Receipt_No_TransPayEntry; TempTransPayEntry."Receipt No.")
            { }
            column(MarkChangeLine; MarkChangeLine)
            { }
            column(Date_TransPayEntry; Format(TempTransPayEntry.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))
            { }
            column(TransType; TransType)
            { }
            column(CardNo; CardNo)
            { }
            column(ContactNo_MemberContactTB; MemberContactTB."Contact No.")
            { }
            column(Name_MemberContactTB; MemberContactTB.Name + ' ' + MemberContactTB."Name 2")
            { }
            column(Amount_Tendered_TransPayEntry; TempTransPayEntry."Amount Tendered")
            { }

            trigger OnPreDataItem()
            begin
                IF Choose1Filter THEN BEGIN
                    DateFilter := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                END
                ELSE
                    IF Choose2Filter THEN BEGIN
                        DateFilter := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    END;

                TempTransPayEntry.Reset();
                TempTransPayEntry.DeleteAll();
                Clear(TmpTenderTypeDesc);
                Clear(TmpMemberCard);

                if DateFilter <> '' then
                    SalesTenderQry.SetFilter(Date_Filter, DateFilter);
                if StoreFilter <> '' then
                    SalesTenderQry.SetFilter(Store_Filter, StoreFilter);
                if POSTerminalFilter <> '' then
                    SalesTenderQry.SetFilter(POS_Terminal_Filter, POSTerminalFilter);

                if CashOnlyFilter then
                    SalesTenderQry.SetFilter(Tender_Type_Filter, '%1|%2', '1', '9')
                else
                    if TenderTypeFilter <> '' then
                        SalesTenderQry.SetFilter(Tender_Type_Filter, TenderTypeFilter);

                if StaffFilter <> '' then
                    SalesTenderQry.SetFilter(Staff_Filter, StaffFilter);
                if ChangeLineFilter then
                    SalesTenderQry.SetRange(Change_Line_Filter, false);

                if SalesTenderQry.Open() then begin
                    while SalesTenderQry.Read() do begin
                        TempTransPayEntry.Init();
                        TempTransPayEntry."Store No." := SalesTenderQry.Store_No_;
                        TempTransPayEntry."POS Terminal No." := SalesTenderQry.POS_Terminal_No_;
                        TempTransPayEntry."Transaction No." := SalesTenderQry.Transaction_No_;
                        TempTransPayEntry."Line No." := SalesTenderQry.Line_No_;
                        TempTransPayEntry."Tender Type" := SalesTenderQry.Tender_Type_;
                        TempTransPayEntry."Receipt No." := SalesTenderQry.Receipt_No_;
                        TempTransPayEntry.Date := SalesTenderQry.Date;
                        TempTransPayEntry."Amount Tendered" := SalesTenderQry.Amount_Tendered;
                        TempTransPayEntry."Change Line" := SalesTenderQry.Change_Line;
                        TempTransPayEntry."Safe type" := SalesTenderQry.Safe_type;
                        TempTransPayEntry.Insert();

                        KeyText := SalesTenderQry.Store_No_ + '_' + SalesTenderQry.Tender_Type_;
                        if not TmpTenderTypeDesc.ContainsKey(KeyText) then begin
                            TmpTenderTypeDesc.Add(KeyText, SalesTenderQry.Tender_Description);
                            TmpTenderInfocode.Add(KeyText, SalesTenderQry.PLSPOS_Infocode_Card_No_);
                        end;

                        KeyTextHeader := SalesTenderQry.Store_No_ + '_' + SalesTenderQry.POS_Terminal_No_ + '_' + Format(SalesTenderQry.Transaction_No_);
                        if (SalesTenderQry.Member_Card_No_ <> '') and (not TmpMemberCard.ContainsKey(KeyTextHeader)) then
                            TmpMemberCard.Add(KeyTextHeader, SalesTenderQry.Member_Card_No_);
                    end;
                    SalesTenderQry.Close();
                end;

                IF (StoreFilter <> '') THEN ReportFilterText += 'Store No : ' + FORMAT(StoreFilter + ' ');
                if POSTerminalFilter <> '' then ReportFilterText += ' POS Terminal No. : ' + POSTerminalFilter;
                if TenderTypeFilter <> '' then ReportFilterText += ' Tender type : ' + TenderTypeFilter;
                if StaffFilter <> '' then ReportFilterText += ' Staff ID : ' + StaffFilter;
                if CashOnlyFilter then ReportFilterText += ' ยอดขายเงินสด';
                if ChangeLineFilter then ReportFilterText += ' ไม่แสดงเงินทอน';

                if TempTransPayEntry.IsEmpty() then
                    CurrReport.Break()
                else
                    TempTransPayEntry.FindSet();
            end;

            trigger OnAfterGetRecord()
            var
                CurrentMemberCard: Code[20];
                CurrentInfocode: Code[20];
            begin
                if Number > 1 then
                    if TempTransPayEntry.Next() = 0 then
                        CurrReport.Break();

                Clear(TransType);
                Clear(MemberShipCardTB);
                Clear(MemberContactTB);

                KeyTextHeader := TempTransPayEntry."Store No." + '_' + TempTransPayEntry."POS Terminal No." + '_' + Format(TempTransPayEntry."Transaction No.");
                if TmpMemberCard.ContainsKey(KeyTextHeader) then begin
                    CurrentMemberCard := TmpMemberCard.Get(KeyTextHeader);
                    if MemberShipCardTB.Get(CurrentMemberCard) then
                        if MemberContactTB.Get(MemberShipCardTB."Account No.", MemberShipCardTB."Contact No.") then;
                end;

                Clear(TenderDescription);
                Clear(CardNo);
                KeyText := TempTransPayEntry."Store No." + '_' + TempTransPayEntry."Tender Type";
                if TmpTenderTypeDesc.ContainsKey(KeyText) then begin
                    TenderDescription := TmpTenderTypeDesc.Get(KeyText);
                    CurrentInfocode := TmpTenderInfocode.Get(KeyText);

                    if CurrentInfocode <> '' then begin
                        Clear(TransInfoEntry);
                        TransInfoEntry.SetCurrentKey("Store No.", "POS Terminal No.", "Transaction No.", "Transaction Type", "Line No.");
                        TransInfoEntry.SetRange("Store No.", TempTransPayEntry."Store No.");
                        TransInfoEntry.SetRange("POS Terminal No.", TempTransPayEntry."POS Terminal No.");
                        TransInfoEntry.SetRange("Transaction No.", TempTransPayEntry."Transaction No.");
                        TransInfoEntry.SetRange("Transaction Type", TransInfoEntry."Transaction Type"::"Payment Entry");
                        TransInfoEntry.SetRange("Line No.", TempTransPayEntry."Line No.");
                        TransInfoEntry.SetRange(Infocode, CurrentInfocode);
                        TransInfoEntry.SetLoadFields(Information);
                        if TransInfoEntry.FindFirst() then
                            CardNo := CopyStr(TransInfoEntry.Information, 1, 4);
                    end;
                end;

                Clear(MarkChangeLine);
                if TempTransPayEntry."Change Line" then
                    MarkChangeLine := 'เงินทอน';
                if TempTransPayEntry."Safe type" <> TempTransPayEntry."Safe type"::" " then
                    MarkChangeLine := Format(TempTransPayEntry."Safe type");
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
                            ToolTip = 'Specifies the store no. to filter the report.';
                        }
                        field("POS Terminal :"; POSTerminalFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'POS Terminal :';
                            ToolTip = 'Specifies the POS Terminal to filter the report.';
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
                            ToolTip = 'Specifies the ยอดขายเงินสด to filter the report.';
                        }
                        field("ไม่แสดงเงินทอน :"; ChangeLineFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'ไม่แสดงเงินทอน :';
                            ToolTip = 'Specifies the ไม่แสดงเงินทอน to filter the report.';
                        }
                        field("Tender Type :"; TenderTypeFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = "LSC Tender Type".Code;
                            Caption = 'Tender Type :';
                            ToolTip = 'Specifies the Tender Type to filter the report.';
                        }
                        field("Staff ID :"; StaffFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = "LSC Staff".ID;
                            Caption = 'Staff ID :';
                            ToolTip = 'Specifies the Staff ID to filter the report.';
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
        // Record
        ComInfo: Record "Company Information";
        MemberContactTB: Record "LSC Member Contact";
        MemberShipCardTB: Record "LSC Membership Card";
        POSTerminalTB: Record "LSC POS Terminal";
        TempTransPayEntry: Record "LSC Trans. Payment Entry" temporary;
        TransInfoEntry: Record "LSC Trans. Infocode Entry";

        // Codeunit
        LSVIPRepFunction: Codeunit "PLSR_Report Function";

        // Query
        SalesTenderQry: Query "TEST_Sales By Tender Query";

        // Other types
        TmpMemberCard: Dictionary of [Text, Code[20]];
        TmpTenderInfocode: Dictionary of [Text, Code[20]];
        TmpTenderTypeDesc: Dictionary of [Text[100], Text[100]];

        CashOnlyFilter: Boolean;
        ChangeLineFilter: Boolean;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;

        CardNo: Text[4];
        DateFilter: Text[100];
        KeyText: Text[100];
        KeyTextHeader: Text;
        MarkChangeLine: Text[30];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        ShowDate: Text[50];
        ShowTime: Text[50];
        TenderDescription: Text[100];
        TransType: Text[50];

        FDateFilter: Date;
        FromDateFilter: Date;
        TodateFilter: Date;

        POSTerminalFilter: Code[20];
        StaffFilter: Code[20];
        StoreFilter: Code[20];
        TenderTypeFilter: Code[20];
}