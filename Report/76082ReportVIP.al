report 50112 "PLSR_Store_Sales_VAT"
{
    Caption = 'Store Sales VAT';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep76082_StoreSalesVAT.rdl';
    PreviewMode = PrintLayout;

    // AVPWDLSVIP 30/06/2026 > Improve Performance of VIP Report(76082) - น้องปอ
    dataset
    {
        dataitem(TransHeader; "LSC Transaction Header")
        {
            DataItemTableView = sorting("Store No.", "POS Terminal No.", "Transaction No.")
                                where("Receipt No." = FILTER(<> ''), "Entry Status" = FILTER(<> Voided));

            trigger OnPreDataItem()
            begin
                IF Choose1Filter THEN BEGIN
                    DateFilter := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    PeriodDate := 'ประจำเดือน '
                                    + LSVIPRepFunction.MonthWords('T', Date2DMY(FromDateFilter, 2)) +
                                    ' ' + Format(DATE2DMY(FromDateFilter, 3) + 543);
                END ELSE
                    IF Choose2Filter THEN BEGIN
                        DateFilter := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        PeriodDate := 'ประจำเดือน '
                                        + LSVIPRepFunction.MonthWords('T', Date2DMY(FDateFilter, 2)) +
                                        ' ' + Format(DATE2DMY(FDateFilter, 3) + 543);
                    END;

                TransHeader.SetFilter(Date, DateFilter);
                if StoreFilter <> '' then
                    TransHeader.SetFilter("Store No.", StoreFilter);

                TransHeader.SetCurrentKey("Store No.", "POS Terminal No.", Date);

                clear(OldBranch);
                clear(OldPOSNo);
                clear(OldTransDate);
                clear(Description);
                clear(Running);
                clear(GroupRunning);
                clear(GroupNetAmt);
                clear(GroupGrossAmt);
                clear(GroupVATAmt);
                clear(FullVATNo);
                clear(VATAmt);
                clear(TransType);
                clear(StoreBranch);

                TempTransactionHeaderTemp.Reset();
                TempTransactionHeaderTemp.DeleteAll();

            end;

            trigger OnAfterGetRecord()
            begin
                clear(StoreBranch);
                clear(StoreTB);

                if StoreTB.Get(TransHeader."Store No.") then;
                StoreBranch := StoreTB."PLSLC_Branch No.";

                GroupRunning := Running;
                clear(FullVATNo);
                if TransHeader."PLSLC_Full VAT No." <> '' then
                    FullVATNo := TransHeader."PLSLC_Full VAT No."
                else
                    FullVATNo := TransHeader."PLSLC_Refund Full VAT No.";

                if (OldBranch <> StoreBranch) or (OldPOSNo <> TransHeader."POS Terminal No.")
                    or (OldTransDate <> TransHeader.Date) then begin
                    IF OldBranch <> StoreBranch THEN BEGIN
                        Running := 1;
                        GroupRunning := 1;
                    END else
                        if (OldPOSNo <> TransHeader."POS Terminal No.") or (OldTransDate <> TransHeader.Date) then begin
                            GroupRunning += 1;
                            Running += 1;
                        end;
                    clear(POSTerminalTB);
                    IF POSTerminalTB.GET(TransHeader."POS Terminal No.") THEN;

                    clear(GroupNetAmt);
                    clear(GroupGrossAmt);
                    clear(GroupVATAmt);
                    OldBranch := StoreBranch;
                    OldPOSNo := TransHeader."POS Terminal No.";
                    OldTransDate := TransHeader.Date;
                    clear(Description);
                    Description := AVGetFirstLastReceiptNo(TransHeader."Store No.", TransHeader."POS Terminal No.", TransHeader.Date);
                end;


                if FullVATNo <> '' then
                    Running += 1;
                clear(VATAmt);
                VATAmt := ROUND((TransHeader."Gross Amount" * -1) - (TransHeader."Net Amount" * -1), 0.01, '=');
                TransType := 'รายได้จากการขาย';
                TempTransactionHeaderTemp.Reset();
                TempTransactionHeaderTemp.SetRange("Member Card No.", Description);
                TempTransactionHeaderTemp.SetRange("Apply to Doc. No.", FullVATNo);

                if not TempTransactionHeaderTemp.FindFirst() then begin

                    TempTransactionHeaderTemp.Init();
                    TempTransactionHeaderTemp."No. of Invoices" := GroupRunning;
                    TempTransactionHeaderTemp."No. of Recomm. Calls" := Running;
                    TempTransactionHeaderTemp."Tax Exemption No." := Format(TransHeader.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    TempTransactionHeaderTemp.Comment := ComInfo.name;
                    TempTransactionHeaderTemp."PLSLC_POS Customer Address 5" := TransType;
                    TempTransactionHeaderTemp."Playback Recording ID" := POSTerminalTB."PLSLC_POS No.";
                    TempTransactionHeaderTemp."Member Card No." := Description;
                    TempTransactionHeaderTemp."Receipt No." := TransHeader."Receipt No.";
                    TempTransactionHeaderTemp."PLSLC_POS Customer Address" := "PLSLC_POS Customer Name";
                    TempTransactionHeaderTemp."PLSLC_POS Customer Address 2" := "PLSLC_POS Customer Name 2";
                    TempTransactionHeaderTemp."PLSLC_POS Customer Address 3" := "PLSLC_POS Customer Name 3";
                    TempTransactionHeaderTemp."PLSLC_POS VAT Registration" := TransHeader."PLSLC_POS VAT Registration";
                    TempTransactionHeaderTemp."PLSLC_POS Branch No." := TransHeader."PLSLC_POS Branch No.";
                    TempTransactionHeaderTemp."Store No." := TransHeader."Store No.";
                    TempTransactionHeaderTemp."POS Terminal No." := TransHeader."POS Terminal No.";
                    TempTransactionHeaderTemp."Transaction No." := TransHeader."Transaction No.";
                    TempTransactionHeaderTemp."Net Amount" := TransHeader."Net Amount";
                    TempTransactionHeaderTemp."No. of Item Lines" := GroupNetAmt;
                    TempTransactionHeaderTemp."No. of Items" := GroupVATAmt;
                    TempTransactionHeaderTemp."No. of Covers" := GroupGrossAmt;
                    if FullVATNo <> '' then begin
                        TempTransactionHeaderTemp."No. of Item Lines" := -TransHeader."Net Amount";
                        TempTransactionHeaderTemp."No. of Items" := ROUND(((TransHeader."Gross Amount" * -1) - (TransHeader."Net Amount" * -1)), 0.01, '=');
                        TempTransactionHeaderTemp."No. of Covers" := -TransHeader."Gross Amount";
                    end;
                    TempTransactionHeaderTemp."Income/Exp. Amount" := VATAmt;
                    TempTransactionHeaderTemp."Gross Amount" := TransHeader."Gross Amount";
                    TempTransactionHeaderTemp."Apply to Doc. No." := FullVATNo;
                    TempTransactionHeaderTemp."PLSLC_POS Customer Address 6" := StoreTB."PLSLC_Branch No.";
                    TempTransactionHeaderTemp.Insert();
                end else begin

                    CurrReport.skip();
                end;

            end;

        }

        dataitem(Integer; Integer)
        {


            DataItemTableView = sorting(Number) where(Number = filter(1 ..));

            column(Number; Number) { }
            column(Name_ComInfo; ComInfo.Name)
            { }
            column(ShowDate; ShowDate)
            { }
            column(ShowTime; ShowTime)
            { }
            column(PeriodDate; PeriodDate)
            { }
            column(VATRegsNo_1; VATRegsNo[1])
            { }
            column(VATRegsNo_2; VATRegsNo[2])
            { }
            column(VATRegsNo_3; VATRegsNo[3])
            { }
            column(VATRegsNo_4; VATRegsNo[4])
            { }
            column(VATRegsNo_5; VATRegsNo[5])
            { }
            column(VATRegsNo_6; VATRegsNo[6])
            { }
            column(VATRegsNo_7; VATRegsNo[7])
            { }
            column(VATRegsNo_8; VATRegsNo[8])
            { }
            column(VATRegsNo_9; VATRegsNo[9])
            { }
            column(VATRegsNo_10; VATRegsNo[10])
            { }
            column(VATRegsNo_11; VATRegsNo[11])
            { }
            column(VATRegsNo_12; VATRegsNo[12])
            { }
            column(VATRegsNo_13; VATRegsNo[13])
            { }
            column(BranchNo; BranchNo)
            { }

            column(StoreBranch; TempTransactionHeaderTemp."PLSLC_POS Customer Address 6")
            { }
            column(Addr_1; Addr[1])
            { }
            column(Addr_2; Addr[2])
            { }
            column(Addr_3; Addr[3])
            { }
            column(Addr_4; Addr[4])
            { }
            column(Addr_5; Addr[5])
            { }

            column(GroupRunning; TempTransactionHeaderTemp."No. of Invoices")
            { }
            column(Running; TempTransactionHeaderTemp."No. of Recomm. Calls")
            { }
            column(Date_TransHeader; TempTransactionHeaderTemp."Tax Exemption No.")
            { }
            column(TransType; TempTransactionHeaderTemp."PLSLC_POS Customer Address 5")
            { }
            column(Description; TempTransactionHeaderTemp."Member Card No.")
            { }
            column(Receipt_No_TransHeader; TempTransactionHeaderTemp."Receipt No.")
            { }
            column(FullVATNo; TempTransactionHeaderTemp."Apply to Doc. No.")
            { }
            column(POS_Customer_Name_TransHeader; TempTransactionHeaderTemp."PLSLC_POS Customer Address" + ' ' + TempTransactionHeaderTemp."PLSLC_POS Customer Address 2" + ' ' + TempTransactionHeaderTemp."PLSLC_POS Customer Address 3")
            { }
            column(POS_VAT_Registration_TransHeader; TempTransactionHeaderTemp."PLSLC_POS VAT Registration")
            { }
            column(POS_Branch_No_TransHeader; TempTransactionHeaderTemp."PLSLC_POS Branch No.")
            { }
            column(Store_No_TransHeader; TempTransactionHeaderTemp."Store No.")
            { }
            column(POS_Terminal_No_TransHeader; TempTransactionHeaderTemp."POS Terminal No.")
            { }
            column(POSNo_POSTerminalTB; TempTransactionHeaderTemp."Playback Recording ID")
            { }
            column(Net_Amount_TransHeader; -TempTransactionHeaderTemp."Net Amount")
            { }
            column(Gross_Amount_TransHeader; -TempTransactionHeaderTemp."Gross Amount")
            { }
            column(VATAmt; TempTransactionHeaderTemp."Income/Exp. Amount")
            { }
            column(GroupNetAmt; TempTransactionHeaderTemp."No. of Item Lines")
            { }
            column(GroupGrossAmt; TempTransactionHeaderTemp."No. of Covers")
            { }
            column(GroupVATAmt; TempTransactionHeaderTemp."No. of Items")
            { }
            column(sum; sum)
            { }


            trigger OnPreDataItem()
            begin
                ComInfo.Get();
                clear(TempTransactionHeaderTemp);
                TempTransactionHeaderTemp.SetCurrentKey("No. of Recomm. Calls", "Store No.");
                TempTransactionHeaderTemp.Ascending(true);
                clear(sum);

            end;

            trigger OnAfterGetRecord()
            begin

                if Number = 1 then begin
                    if NOT TempTransactionHeaderTemp.find('-') then
                        CurrReport.Break();
                end else
                    if TempTransactionHeaderTemp.Next() = 0 then
                        CurrReport.Break();
                MarkBrach(TempTransactionHeaderTemp);
                AVGetStoreDetail(TempTransactionHeaderTemp);

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
                    group("Store Filter")
                    {
                        field("Store :"; StoreFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = "LSC Store"."No.";
                            Caption = 'Store :';
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
        end;

    }

    trigger OnPreReport()
    begin
        SelectLatestVersion();
        ComInfo.Get();
        ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
        GetVATRegisNo();
    end;

    var

        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        TempTransactionHeaderTemp: Record "LSC Transaction Header" temporary;
        ComInfo: Record "Company Information";
        StoreTB: Record "LSC Store";
        VATBussPostTB: Record "VAT Business Posting Group";
        POSTerminalTB: Record "LSC POS Terminal";
        ShowTime: Text[50];
        ShowDate: Text[50];
        DateFilter: Text[100];
        PeriodDate: Text;
        StoreFilter: Code[20];
        FullVATNo: Code[20];
        OldBranch: Text[50];
        OldPOSNo: Code[20];
        VATRegsNo: array[13] of Text[1];
        BranchNo: Text;
        Description: Text;
        Addr: array[5] of Text[100];
        TransType: Text[50];
        OldTransDate: Date;
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        Running: Integer;
        GroupRunning: Integer;
        GroupNetAmt: Decimal;
        GroupGrossAmt: Decimal;
        GroupVATAmt: Decimal;
        VATAmt: Decimal;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        StoreBranch: Text[50];
        sum: Decimal;

    local procedure GetVATRegisNo()
    var
        i: Integer;
    begin
        clear(VATRegsNo);
        repeat
            i += 1;
            VATRegsNo[i] := CopyStr(ComInfo."VAT Registration No.", i, 1);
        until i = 13;
    end;

    local procedure MarkBrach(TempTransH: Record "LSC Transaction Header" temporary)
    begin
        clear(VATBussPostTB);
        clear(BranchNo);
        clear(StoreTB);
        if StoreTB.Get(TempTransH."Store No.") then
            if VATBussPostTB.Get(StoreTB."Store VAT Bus. Post. Gr.") then
                if (VATBussPostTB."AVF_Branch No." = '00000') or (VATBussPostTB."AVF_Branch No." = '0000') then
                    BranchNo := 'สำนักงานใหญ่'
                else
                    BranchNo := 'สาขาที่ : ' + StoreTB."PLSLC_Branch No.";
    end;

    local procedure AVGetFirstLastReceiptNo(StoreNo: Code[10]; POSTerminalNo: Code[10]; TransDate: Date): Text
    var
        ReceiptTxt: Text;
        TransHTB: Record "LSC Transaction Header";
        SalesVATAmtQuery: Query "PLSR_StoreSalesVATAmt_Q";
    begin
        clear(ReceiptTxt);
        clear(TransHTB);
        TransHTB.SETCURRENTKEY("Store No.", "POS Terminal No.", "Transaction No.");
        TransHTB.SETRANGE("Store No.", StoreNo);
        TransHTB.SETRANGE("POS Terminal No.", POSTerminalNo);
        TransHTB.SETRANGE(Date, TransDate);
        TransHTB.SETFILTER("Receipt No.", '<>%1', '');
        TransHTB.SETFILTER("Entry Status", '<>%1', TransHTB."Entry Status"::Voided);
        TransHTB.SetLoadFields("Receipt No.");
        IF TransHTB.FINDFIRST() THEN
            ReceiptTxt := TransHTB."Receipt No.";
        IF TransHTB.FINDLAST() THEN
            ReceiptTxt := ReceiptTxt + ' - ' + TransHTB."Receipt No.";

        clear(SalesVATAmtQuery);
        SalesVATAmtQuery.SetRange(Store_No, StoreNo);
        SalesVATAmtQuery.SetRange(POS_Terminal_No, POSTerminalNo);
        SalesVATAmtQuery.SetRange(Date_Filter, TransDate);
        SalesVATAmtQuery.SetFilter(Receipt_No, '<>%1', '');
        SalesVATAmtQuery.SetFilter(Full_VAT_No, '%1', '');
        SalesVATAmtQuery.SetFilter(Refund_Full_VAT_No, '%1', '');
        SalesVATAmtQuery.SetFilter(Entry_Status, '<>%1', TransHTB."Entry Status"::Voided);
        if SalesVATAmtQuery.Open() then begin
            if SalesVATAmtQuery.Read() then begin
                GroupNetAmt += SalesVATAmtQuery.Sum_Net_Amount * -1;
                GroupGrossAmt += SalesVATAmtQuery.Sum_Gross_Amount * -1;
                GroupVATAmt += ROUND(((SalesVATAmtQuery.Sum_Gross_Amount * -1) - (SalesVATAmtQuery.Sum_Net_Amount * -1)), 0.01, '=');
            end;
            SalesVATAmtQuery.Close();
        end;

        EXIT(ReceiptTxt);
    end;

    local procedure AVGetStoreDetail(TempTransactionHeaderTemp: Record "LSC Transaction Header" temporary)
    begin
        clear(Addr);
        clear(StoreTB);
        if StoreTB.Get(TempTransactionHeaderTemp."Store No.") then
            if StoreTB."PLSLC_Show Full Vat At HQ" then begin
                Addr[1] := ComInfo.Address;
                Addr[2] := ComInfo."Address 2";
                Addr[3] := ComInfo.City + ' ' + ComInfo.County + ' ' + ComInfo."Post Code";
            end else begin
                Addr[1] := StoreTB.Address;
                Addr[2] := StoreTB."Address 2";
                Addr[3] := StoreTB."PLSLC_Address 3";
                Addr[4] := StoreTB."PLSLC_Address 4";
                Addr[5] := StoreTB."PLSLC_Address 5";
            end;
    end;
    // AVPWDLSVIP 30/06/2026 > Improve Performance of VIP Report(76082) - น้องปอ
}
