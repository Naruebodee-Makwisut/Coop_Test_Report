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
            // เปลี่ยนมาดึงค่าผ่านตัวแปร TmpTransHeader แทนตารางจริง
            column(Date_TransHeader; Format(TmpTransHeader.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>'))
            { }
            column(Receipt_No_TransHeader; TmpTransHeader."Receipt No.")
            { }
            column(Full_VAT_No_TransHeader; FullVATNo)
            { }
            column(POSNo_POSTerminalTB; POSTerminalTB."PLSLC_POS No.")
            { }
            column(TransType; TransType)
            { }
            column(POS_Customer_Name; TmpTransHeader."PLSLC_POS Customer Name" + ' ' + TmpTransHeader."PLSLC_POS Customer Name 2" + ' ' + TmpTransHeader."PLSLC_POS Customer Name 3")
            { }
            column(POS_VAT_Registration_TransHeader; TmpTransHeader."PLSLC_POS VAT Registration")
            { }
            column(POS_Branch_No_TransHeader; TmpTransHeader."PLSLC_POS Branch No.")
            { }
            column(Store_No_TransHeader; TmpTransHeader."Store No.")
            { }
            column(POS_Terminal_No_; TmpTransHeader."POS Terminal No.")
            { }
            column(Transaction_No_; TmpTransHeader."Transaction No.")
            { }
            column(Net_Amount_TransHeader; -TmpTransHeader."Net Amount")
            { }
            column(VATAmount_TransHeader; VATAmount)
            { }
            column(Gross_Amount_TransHeader; -TmpTransHeader."Gross Amount")
            { }
            column(Rounded_TransHeader; -TmpTransHeader.Rounded)
            { }

            trigger OnPreDataItem()
            begin
                // --- 1. จัดการ DateFilter และ Text เหมือนเดิม ---
                IF Choose1Filter THEN BEGIN
                    DateFilter := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                END
                ELSE
                    IF Choose2Filter THEN BEGIN
                        DateFilter := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    END;
                if StoreFilter <> '' then begin
                    ReportFilterText := 'Store No.: ' + StoreFilter;
                end;

                // --- 2. เคลียร์ตัวแปร Temporary Table ใน Memory ---
                TmpTransHeader.Reset();
                TmpTransHeader.DeleteAll();
                TmpStore.Reset();
                TmpStore.DeleteAll();
                TmpPOSTerminal.Reset();
                TmpPOSTerminal.DeleteAll();

                // --- 3. ดึงข้อมูลจาก Query ยัดเข้าตัวแปร Temp ตรง ๆ ---
                StoreVATQry.SetFilter(Receipt_No_Filter, '<>%1', '');
                StoreVATQry.SetFilter(Entry_Status_Filter, '<>%1', StoreVATQry.Entry_Status_Filter::Voided);
                if DateFilter <> '' then
                    StoreVATQry.SetFilter(Date_Filter, DateFilter);
                if StoreFilter <> '' then
                    StoreVATQry.SetRange(Store_Filter, StoreFilter);

                if StoreVATQry.Open() then begin
                    while StoreVATQry.Read() do begin
                        TmpTransHeader.Init();
                        TmpTransHeader."Store No." := StoreVATQry.Store_No_;
                        TmpTransHeader."POS Terminal No." := StoreVATQry.POS_Terminal_No_;
                        TmpTransHeader."Transaction No." := StoreVATQry.Transaction_No_;
                        TmpTransHeader."Receipt No." := StoreVATQry.Receipt_No_;
                        TmpTransHeader.Date := StoreVATQry.Date;
                        TmpTransHeader."Net Amount" := StoreVATQry.Net_Amount;
                        TmpTransHeader."Gross Amount" := StoreVATQry.Gross_Amount;
                        TmpTransHeader.Rounded := StoreVATQry.Rounded;
                        TmpTransHeader."Sale Is Return Sale" := StoreVATQry.Sale_Is_Return_Sale;
                        TmpTransHeader."PLSLC_Refund Full VAT No." := StoreVATQry.PLSLC_Refund_Full_VAT_No_;
                        TmpTransHeader."PLSLC_Full VAT No." := StoreVATQry.PLSLC_Full_VAT_No_;
                        TmpTransHeader."PLSLC_POS Customer Name" := StoreVATQry.PLSLC_POS_Customer_Name;
                        TmpTransHeader."PLSLC_POS Customer Name 2" := StoreVATQry.PLSLC_POS_Customer_Name_2;
                        TmpTransHeader."PLSLC_POS Customer Name 3" := StoreVATQry.PLSLC_POS_Customer_Name_3;
                        TmpTransHeader."PLSLC_POS VAT Registration" := StoreVATQry.PLSLC_POS_VAT_Registration;
                        TmpTransHeader."PLSLC_POS Branch No." := StoreVATQry.PLSLC_POS_Branch_No_;
                        TmpTransHeader.Insert();

                        if not TmpStore.Get(StoreVATQry.Store_No_) then begin
                            TmpStore.Init();
                            TmpStore."No." := StoreVATQry.Store_No_;
                            TmpStore."PLSLC_Branch No." := StoreVATQry.PLSLC_Branch_No_;
                            TmpStore."PLSLC_Show Full Vat At HQ" := StoreVATQry.PLSLC_Show_Full_Vat_At_HQ;
                            TmpStore.Address := StoreVATQry.Store_Address;
                            TmpStore."Address 2" := StoreVATQry.Store_Address_2;
                            TmpStore."PLSLC_Address 3" := StoreVATQry.PLSLC_Address_3;
                            TmpStore."PLSLC_Address 4" := StoreVATQry.PLSLC_Address_4;
                            TmpStore."PLSLC_Address 5" := StoreVATQry.PLSLC_Address_5;
                            TmpStore.Insert();
                        end;

                        if not TmpPOSTerminal.Get(StoreVATQry.POS_Terminal_No_) then begin
                            TmpPOSTerminal.Init();
                            TmpPOSTerminal."No." := StoreVATQry.POS_Terminal_No_;
                            TmpPOSTerminal."PLSLC_POS No." := StoreVATQry.PLSLC_POS_No_;
                            TmpPOSTerminal.Insert();
                        end;
                    end;
                    StoreVATQry.Close();
                end;

                // ตรวจสอบข้อมูลใน Temp ถ้าไม่มีบิลเลยให้ยกเลิกการพิมพ์ loop นี้ไปเลย
                if TmpTransHeader.IsEmpty() then
                    CurrReport.Break()
                else begin
                    TmpTransHeader.SetCurrentKey("Store No.", "POS Terminal No.", "Transaction No.");
                    TmpTransHeader.FindSet(); // เลื่อน Pointer ไปที่ตัวแรกเตรียมพร้อมให้ลูปเริ่มทำงาน
                end;

            end;

            trigger OnAfterGetRecord()
            begin
                // วนลูป Integer ไปเรื่อย ๆ โดยเช็ค Pointer ข้อมูลใน TmpTransHeader
                if Number > 1 then begin
                    if TmpTransHeader.Next() = 0 then
                        CurrReport.Break(); // ถ้าหมดข้อมูลในคลังแล้ว ให้สั่งหลุดลูป Integer ทันที
                end;

                Clear(FullVATNo);
                Clear(StoreTB);
                Clear(AddrText);

                // ดึงข้อมูล Store มาสเตอร์จากตัวแปร Temp ใน memory
                if TmpStore.Get(TmpTransHeader."Store No.") then begin
                    StoreTB := TmpStore;
                    if TmpStore."PLSLC_Show Full Vat At HQ" then begin
                        AddrText[1] := ComInfo.Address;
                        AddrText[2] := ComInfo."Address 2";
                        AddrText[3] := ComInfo.City + ' ' + ComInfo.County + ' ' + ComInfo."Post Code";
                    end else begin
                        AddrText[1] := TmpStore.Address;
                        AddrText[2] := TmpStore."Address 2";
                        AddrText[3] := TmpStore."PLSLC_Address 3";
                        AddrText[4] := TmpStore."PLSLC_Address 4";
                        AddrText[5] := TmpStore."PLSLC_Address 5";
                    end;
                end;

                if OldStoreNo <> TmpTransHeader."Store No." then begin
                    OldStoreNo := TmpTransHeader."Store No.";
                    Clear(RunningNum);
                end;
                RunningNum += 1;

                Clear(VATAmount);
                VATAmount := Round((-TmpTransHeader."Gross Amount") - (-TmpTransHeader."Net Amount"), 0.01, '=');

                // ดึงข้อมูล POS Terminal มาสเตอร์จากตัวแปร Temp ใน memory
                Clear(POSTerminalTB);
                if TmpPOSTerminal.Get(TmpTransHeader."POS Terminal No.") then
                    POSTerminalTB := TmpPOSTerminal;

                Clear(TransType);
                if (TmpTransHeader."Sale Is Return Sale") then begin
                    TransType := 'Refund';
                    FullVATNo := TmpTransHeader."PLSLC_Refund Full VAT No.";
                end else begin
                    TransType := 'Sales';
                    FullVATNo := TmpTransHeader."PLSLC_Full VAT No.";
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
        SelectLatestVersion();
        ComInfo.Get();
        ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
    end;

    var
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        StoreTB: Record "LSC Store";
        VATBussTB: Record "VAT Business Posting Group";
        POSTerminalTB: Record "LSC POS Terminal";
        StoreVATQry: Query "TEST_Store Sales VAT Query";

        // >>> ประกาศตัวแปรตารางชั่วคราว (Temporary Variables) แบบชัดเจนตรงนี้ <<<
        TmpTransHeader: Record "LSC Transaction Header" temporary;
        TmpStore: Record "LSC Store" temporary;
        TmpPOSTerminal: Record "LSC POS Terminal" temporary;

        ShowTime: Text[50];
        ShowDate: Text[50];
        DateFilter: Text[100];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        TransType: Text[50];
        AddrText: array[5] of Text[100];
        StoreFilter: Code[20];
        OldStoreNo: Code[20];
        FullVATNo: code[20];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        RunningNum: Integer;
        VATAmount: Decimal;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
}