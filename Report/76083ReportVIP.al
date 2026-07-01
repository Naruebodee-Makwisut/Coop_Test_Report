report 50113 "TEST_Sale VAT by Rec_Test"
{
    Caption = 'Store Sales VAT By Receipt';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50113_StoreSalesVATByReceipt.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));

            column(Name_ComInfo; ComInfo.Name)
            { }
            column(Branch_No_Store; StoreTB."PLSLC_Branch No.")
            { }
            column(Addr1_Store; AddrText[1])
            { }
            column(Addr2_Store; AddrText[2])
            { }
            column(Addr3_Store; AddrText[3])
            { }
            column(Addr4_Store; AddrText[4])
            { }
            column(Addr5_Store; AddrText[5])
            { }
            column(VatRegistorNo_ComInfo; ComInfo."VAT Registration No.")
            { }
            column(ShowDate; ShowDate)
            { }
            column(ShowTime; ShowTime)
            { }
            column(PeriodDate; PeriodDate)
            { }
            column(ReportFilterText; ReportFilterText)
            { }
            column(RunningNum; RunningNum)
            { }
            // เปลี่ยนมาดึงค่าผ่านตัวแปร TempTransHeader แทนตารางจริง
            column(Date_TransHeader; Format(TempTransHeader.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))
            { }
            column(Receipt_No_TransHeader; TempTransHeader."Receipt No.")
            { }
            column(Full_VAT_No_TransHeader; FullVATNo)
            { }
            column(POSNo_POSTerminalTB; POSTerminalTB."PLSLC_POS No.")
            { }
            column(TransType; TransType)
            { }
            column(POS_Customer_Name; TempTransHeader."PLSLC_POS Customer Name" + ' ' + TempTransHeader."PLSLC_POS Customer Name 2" + ' ' + TempTransHeader."PLSLC_POS Customer Name 3")
            { }
            column(POS_VAT_Registration_TransHeader; TempTransHeader."PLSLC_POS VAT Registration")
            { }
            column(POS_Branch_No_TransHeader; TempTransHeader."PLSLC_POS Branch No.")
            { }
            column(Store_No_TransHeader; TempTransHeader."Store No.")
            { }
            column(POS_Terminal_No_; TempTransHeader."POS Terminal No.")
            { }
            column(Transaction_No_; TempTransHeader."Transaction No.")
            { }
            column(Net_Amount_TransHeader; -TempTransHeader."Net Amount")
            { }
            column(VATAmount_TransHeader; VATAmount)
            { }
            column(Gross_Amount_TransHeader; -TempTransHeader."Gross Amount")
            { }
            column(Rounded_TransHeader; -TempTransHeader.Rounded)
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
                if StoreFilter <> '' then
                    ReportFilterText := 'Store No.: ' + StoreFilter;

                TempTransHeader.Reset();
                TempTransHeader.DeleteAll();
                TempStore.Reset();
                TempStore.DeleteAll();
                TempPOSTerminal.Reset();
                TempPOSTerminal.DeleteAll();

                StoreVATQry.SetFilter(Receipt_No_Filter, '<>%1', '');
                StoreVATQry.SetFilter(Entry_Status_Filter, '<>%1', StoreVATQry.Entry_Status_Filter::Voided);
                if DateFilter <> '' then
                    StoreVATQry.SetFilter(Date_Filter, DateFilter);
                if StoreFilter <> '' then
                    StoreVATQry.SetRange(Store_Filter, StoreFilter);

                if StoreVATQry.Open() then begin
                    while StoreVATQry.Read() do begin
                        TempTransHeader.Init();
                        TempTransHeader."Store No." := StoreVATQry.Store_No_;
                        TempTransHeader."POS Terminal No." := StoreVATQry.POS_Terminal_No_;
                        TempTransHeader."Transaction No." := StoreVATQry.Transaction_No_;
                        TempTransHeader."Receipt No." := StoreVATQry.Receipt_No_;
                        TempTransHeader.Date := StoreVATQry.Date;
                        TempTransHeader."Net Amount" := StoreVATQry.Net_Amount;
                        TempTransHeader."Gross Amount" := StoreVATQry.Gross_Amount;
                        TempTransHeader.Rounded := StoreVATQry.Rounded;
                        TempTransHeader."Sale Is Return Sale" := StoreVATQry.Sale_Is_Return_Sale;
                        TempTransHeader."PLSLC_Refund Full VAT No." := StoreVATQry.PLSLC_Refund_Full_VAT_No_;
                        TempTransHeader."PLSLC_Full VAT No." := StoreVATQry.PLSLC_Full_VAT_No_;
                        TempTransHeader."PLSLC_POS Customer Name" := StoreVATQry.PLSLC_POS_Customer_Name;
                        TempTransHeader."PLSLC_POS Customer Name 2" := StoreVATQry.PLSLC_POS_Customer_Name_2;
                        TempTransHeader."PLSLC_POS Customer Name 3" := StoreVATQry.PLSLC_POS_Customer_Name_3;
                        TempTransHeader."PLSLC_POS VAT Registration" := StoreVATQry.PLSLC_POS_VAT_Registration;
                        TempTransHeader."PLSLC_POS Branch No." := StoreVATQry.PLSLC_POS_Branch_No_;
                        TempTransHeader.Insert();

                        if not TempStore.Get(StoreVATQry.Store_No_) then begin
                            TempStore.Init();
                            TempStore."No." := StoreVATQry.Store_No_;
                            TempStore."PLSLC_Branch No." := StoreVATQry.PLSLC_Branch_No_;
                            TempStore."PLSLC_Show Full Vat At HQ" := StoreVATQry.PLSLC_Show_Full_Vat_At_HQ;
                            TempStore.Address := StoreVATQry.Store_Address;
                            TempStore."Address 2" := StoreVATQry.Store_Address_2;
                            TempStore."PLSLC_Address 3" := StoreVATQry.PLSLC_Address_3;
                            TempStore."PLSLC_Address 4" := StoreVATQry.PLSLC_Address_4;
                            TempStore."PLSLC_Address 5" := StoreVATQry.PLSLC_Address_5;
                            TempStore.Insert();
                        end;

                        if not TempPOSTerminal.Get(StoreVATQry.POS_Terminal_No_) then begin
                            TempPOSTerminal.Init();
                            TempPOSTerminal."No." := StoreVATQry.POS_Terminal_No_;
                            TempPOSTerminal."PLSLC_POS No." := StoreVATQry.PLSLC_POS_No_;
                            TempPOSTerminal.Insert();
                        end;
                    end;
                    StoreVATQry.Close();
                end;

                if TempTransHeader.IsEmpty() then
                    CurrReport.Break()
                else
                    TempTransHeader.FindSet();

            end;

            trigger OnAfterGetRecord()
            begin
                if Number > 1 then
                    if TempTransHeader.Next() = 0 then
                        CurrReport.Break(); // ถ้าหมดข้อมูลในคลังแล้ว ให้สั่งหลุดลูป Integer ทันที

                Clear(FullVATNo);
                Clear(StoreTB);
                Clear(AddrText);

                if TempStore.Get(TempTransHeader."Store No.") then begin
                    StoreTB := TempStore;
                    if TempStore."PLSLC_Show Full Vat At HQ" then begin
                        AddrText[1] := ComInfo.Address;
                        AddrText[2] := ComInfo."Address 2";
                        AddrText[3] := ComInfo.City + ' ' + ComInfo.County + ' ' + ComInfo."Post Code";
                    end else begin
                        AddrText[1] := TempStore.Address;
                        AddrText[2] := TempStore."Address 2";
                        AddrText[3] := TempStore."PLSLC_Address 3";
                        AddrText[4] := TempStore."PLSLC_Address 4";
                        AddrText[5] := TempStore."PLSLC_Address 5";
                    end;
                end;

                if OldStoreNo <> TempTransHeader."Store No." then begin
                    OldStoreNo := TempTransHeader."Store No.";
                    Clear(RunningNum);
                end;
                RunningNum += 1;

                Clear(VATAmount);
                VATAmount := Round((-TempTransHeader."Gross Amount") - (-TempTransHeader."Net Amount"), 0.01, '=');

                Clear(POSTerminalTB);
                if TempPOSTerminal.Get(TempTransHeader."POS Terminal No.") then
                    POSTerminalTB := TempPOSTerminal;

                Clear(TransType);
                if (TempTransHeader."Sale Is Return Sale") then begin
                    TransType := 'Refund';
                    FullVATNo := TempTransHeader."PLSLC_Refund Full VAT No.";
                end else begin
                    TransType := 'Sales';
                    FullVATNo := TempTransHeader."PLSLC_Full VAT No.";
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
        SelectLatestVersion();
        ComInfo.Get();
        ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
    end;

    var
        // Record
        ComInfo: Record "Company Information";
        POSTerminalTB: Record "LSC POS Terminal";
        StoreTB: Record "LSC Store";
        TempPOSTerminal: Record "LSC POS Terminal" temporary;
        TempStore: Record "LSC Store" temporary;
        TempTransHeader: Record "LSC Transaction Header" temporary;
        // VATBussTB: Record "VAT Business Posting Group";

        LSVIPRepFunction: Codeunit "PLSR_Report Function";

        StoreVATQry: Query "TEST_Store Sales VAT Query";

        Choose1Filter: Boolean;
        Choose2Filter: Boolean;

        FDateFilter: Date;
        FromDateFilter: Date;
        TodateFilter: Date;

        VATAmount: Decimal;

        RunningNum: Integer;

        AddrText: array[5] of Text[100];

        DateFilter: Text[100];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        ShowDate: Text[50];
        ShowTime: Text[50];
        TransType: Text[50];

        FullVATNo: Code[20];
        OldStoreNo: Code[20];
        StoreFilter: Code[20];
}