report 50109 "Sales_Report_By_Terminal"
{
    Caption = 'POS Sales Report by Terminal';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50109_POSSalesReportByTerminal.rdl';
    PreviewMode = PrintLayout;
    DataAccessIntent = ReadOnly;

    // AVPWDLSVIP 03/07/2026 > Improve Performance of VIP Report(76075) - น้องปอ
    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number);

            column(Variant_Code; VariantCodeList.Get(Number))
            { }
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
            column(Store_No_TransSale; StoreNoList.Get(Number))
            { }
            column(POS_Terminal_No_TransSale; POSTerminalNoList.Get(Number))
            { }
            column(Receipt_No_TransSale; ReceiptNoList.Get(Number))
            { }
            column(Date_TransSale; DateTextList.Get(Number))
            { }
            column(TransType; TransTypeList.Get(Number))
            { }
            column(CancelDocNo; CancelDocNoList.Get(Number))
            { }
            column(RefundDocNo; RefundDocNoList.Get(Number))
            { }
            column(RefRefund; RefRefundList.Get(Number))
            { }
            column(Item_No_TransSale; ItemNoList.Get(Number))
            { }
            column(Item_Name_ItemTB; ItemDescList.Get(Number))
            { }
            column(Contact_No_MemberContact; MemberCardNoList.Get(Number))
            { }
            column(Name_MemberContact; MemberContactNameList.Get(Number))
            { }
            column(Unit_of_Measure_TransSale; UOMList.Get(Number))
            { }
            column(Qty; QtyList.Get(Number))
            { }
            column(BaseQty; BaseQtyList.Get(Number))
            { }
            column(UnitPrice; UnitPriceList.Get(Number))
            { }
            column(Amount; AmountList.Get(Number))
            { }
            column(Discount_Amount_TransSale; DiscountAmountList.Get(Number))
            { }
            column(TotalAmt; TotalAmtList.Get(Number))
            { }
            column(ShowVariant; ShowVariantFlag)
            { }
            column(TransHeaderTB_Time; HeaderTimeList.Get(Number))
            { }

            trigger OnPreDataItem()
            begin
                RettailSetup.Get();
                ShowVariantFlag := not RettailSetup."PLSPOS_Show Var for Report VIP";

                Clear(ReportFilterText);

                IF Choose1Filter THEN
                    PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')
                ELSE
                    IF Choose2Filter THEN
                        PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');

                IF (StoreFilter <> '') THEN
                    ReportFilterText += 'Store No : ' + FORMAT(StoreFilter + ' ');
                IF (ItemNoFilter <> '') THEN
                    ReportFilterText += ' Item No: ' + FORMAT(ItemNoFilter + ' ');
                IF (POSTerminalFilter <> '') THEN
                    ReportFilterText += ' POS Terminal No. : ' + FORMAT(POSTerminalFilter + ' ');

                PrecomputeReportLines();

                Integer.SetRange(Number, 1, VariantCodeList.Count);
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
                        field("Item No. :"; ItemNoFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = Item."No.";
                            Caption = 'Item No. :';
                        }
                        field("POS Terminal No. :"; POSTerminalFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'POS Terminal No. :';
                            trigger OnLookup(VAR Text: Text): Boolean
                            begin
                                Clear(POSTerminalTB);
                                if StoreFilter <> '' then
                                    POSTerminalTB.SetRange("Store No.", StoreFilter);
                                if POSTerminalTB.FindSet() then
                                    if Page.RunModal(Page::"LSC POS Terminal List", POSTerminalTB) = Action::LookupOK then
                                        POSTerminalFilter := POSTerminalTB."No.";
                            end;
                        }
                        field("Refund Transaction :"; RefundFilter)
                        {
                            Caption = 'Refund Transaction :';
                            OptionCaption = ' ,Yes,No';
                            ApplicationArea = All;
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
            SelectLatestVersion();
        end;
    }

    trigger OnPreReport()
    begin
        ComInfo.Get();
        ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
    end;

    local procedure PrecomputeReportLines()
    var
        ItemDescCache: Dictionary of [Code[20], Text[100]];
        MemberContactNameCache: Dictionary of [Code[20], Text[100]];
        RefundVoidedCache: Dictionary of [Code[20], Boolean];
        DateTextCache: Dictionary of [Date, Text[50]];
        TimeTextCache: Dictionary of [Time, Text[50]];
        LocalMemberShipCardTB: Record "LSC Membership Card";
        DateFilterText: Text[100];
        LocalTransType: Text[50];
        LocalCancelDocNo: Text[30];
        LocalRefundDocNo: Text[30];
        LocalItemDesc: Text[100];
        LocalMemberContactName: Text[100];
        LocalDateText: Text[50];
        LocalTimeText: Text[50];
        LocalQty: Decimal;
        LocalBaseQty: Decimal;
        LocalUnitPrice: Decimal;
        LocalAmount: Decimal;
    begin
        Clear(VariantCodeList);
        Clear(StoreNoList);
        Clear(POSTerminalNoList);
        Clear(ReceiptNoList);
        Clear(DateTextList);
        Clear(UOMList);
        Clear(ItemNoList);
        Clear(ItemDescList);
        Clear(MemberCardNoList);
        Clear(MemberContactNameList);
        Clear(QtyList);
        Clear(BaseQtyList);
        Clear(UnitPriceList);
        Clear(AmountList);
        Clear(TotalAmtList);
        Clear(DiscountAmountList);
        Clear(TransTypeList);
        Clear(CancelDocNoList);
        Clear(RefundDocNoList);
        Clear(RefRefundList);
        Clear(HeaderTimeList);

        ItemTB.SetLoadFields(Description, "Description 2");
        MemberContactTB.SetLoadFields(Name, "Name 2");
        TransHTb.SetLoadFields("Entry Status");

        IF Choose1Filter THEN
            DateFilterText := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')
        ELSE
            IF Choose2Filter THEN
                DateFilterText := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');

        IF DateFilterText <> '' THEN
            POSSaleQuery.SetFilter(EntryDate, DateFilterText);
        IF StoreFilter <> '' THEN
            POSSaleQuery.SetFilter(StoreNo, StoreFilter);
        IF ItemNoFilter <> '' THEN
            POSSaleQuery.SetFilter(ItemNo, ItemNoFilter);
        IF POSTerminalFilter <> '' THEN
            POSSaleQuery.SetFilter(POSTerminalNo, POSTerminalFilter);
        if RefundFilter = RefundFilter::Yes then
            POSSaleQuery.SetFilter(ReturnNoSale, '%1', true)
        else
            if RefundFilter = RefundFilter::No then
                POSSaleQuery.SetFilter(ReturnNoSale, '%1', false);

        POSSaleQuery.Open();
        while POSSaleQuery.Read() do begin
            LocalTransType := Format(POSSaleQuery.HeaderTransactionType);
            if POSSaleQuery.ReturnNoSale then
                LocalTransType := 'Refund';

            Clear(LocalRefundDocNo);
            Clear(LocalCancelDocNo);
            if POSSaleQuery.HeaderSaleIsReturnSale then
                LocalRefundDocNo := 'Refund Manual';
            if POSSaleQuery.HeaderRetrievedFromReceiptNo <> '' then
                LocalRefundDocNo := POSSaleQuery.HeaderRetrievedFromReceiptNo;
            if POSSaleQuery.HeaderRefundReceiptNo <> '' then
                LocalCancelDocNo := POSSaleQuery.HeaderRefundReceiptNo;

            if LocalCancelDocNo <> '' then begin
                if not RefundVoidedCache.ContainsKey(POSSaleQuery.HeaderRefundReceiptNo) then begin
                    TransHTb.SetCurrentKey("Receipt No.");
                    TransHTb.SetRange("Receipt No.", POSSaleQuery.HeaderRefundReceiptNo);
                    if TransHTb.FindFirst() then
                        RefundVoidedCache.Add(POSSaleQuery.HeaderRefundReceiptNo, TransHTb."Entry Status" = TransHTb."Entry Status"::Voided)
                    else
                        RefundVoidedCache.Add(POSSaleQuery.HeaderRefundReceiptNo, false);
                end;
                if RefundVoidedCache.Get(POSSaleQuery.HeaderRefundReceiptNo) then
                    LocalCancelDocNo := '';
            end;

            if not ItemDescCache.ContainsKey(POSSaleQuery.ItemNo) then begin
                if ItemTB.Get(POSSaleQuery.ItemNo) then
                    ItemDescCache.Add(POSSaleQuery.ItemNo, ItemTB.Description + ' ' + ItemTB."Description 2")
                else
                    ItemDescCache.Add(POSSaleQuery.ItemNo, '');
            end;
            LocalItemDesc := ItemDescCache.Get(POSSaleQuery.ItemNo);

            LocalMemberContactName := '';
            if POSSaleQuery.HeaderMemberCardNo <> '' then begin
                if not MemberContactNameCache.ContainsKey(POSSaleQuery.HeaderMemberCardNo) then begin
                    Clear(LocalMemberShipCardTB);
                    if LocalMemberShipCardTB.Get(POSSaleQuery.HeaderMemberCardNo) then;
                    if MemberContactTB.Get(LocalMemberShipCardTB."Account No.", LocalMemberShipCardTB."Contact No.") then
                        MemberContactNameCache.Add(POSSaleQuery.HeaderMemberCardNo, MemberContactTB.Name + ' ' + MemberContactTB."Name 2")
                    else
                        MemberContactNameCache.Add(POSSaleQuery.HeaderMemberCardNo, '');
                end;
                LocalMemberContactName := MemberContactNameCache.Get(POSSaleQuery.HeaderMemberCardNo);
            end;

            if POSSaleQuery.UOMQuantity <> 0 then
                LocalQty := -POSSaleQuery.UOMQuantity
            else
                LocalQty := -POSSaleQuery.Quantity;
            if POSSaleQuery.UOMPrice <> 0 then
                LocalUnitPrice := POSSaleQuery.UOMPrice
            else
                LocalUnitPrice := POSSaleQuery.Price;
            LocalBaseQty := -POSSaleQuery.Quantity;
            LocalAmount := LocalUnitPrice * LocalQty;

            if not DateTextCache.ContainsKey(POSSaleQuery.EntryDate) then
                DateTextCache.Add(POSSaleQuery.EntryDate, Format(POSSaleQuery.EntryDate, 0, '<Closing><Day,2>/<Month,2>/<Year4>'));
            LocalDateText := DateTextCache.Get(POSSaleQuery.EntryDate);

            if not TimeTextCache.ContainsKey(POSSaleQuery.HeaderTime) then
                TimeTextCache.Add(POSSaleQuery.HeaderTime, Format(POSSaleQuery.HeaderTime));
            LocalTimeText := TimeTextCache.Get(POSSaleQuery.HeaderTime);

            VariantCodeList.Add(POSSaleQuery.VariantCode);
            StoreNoList.Add(POSSaleQuery.StoreNo);
            POSTerminalNoList.Add(POSSaleQuery.POSTerminalNo);
            ReceiptNoList.Add(POSSaleQuery.ReceiptNo);
            DateTextList.Add(LocalDateText);
            UOMList.Add(POSSaleQuery.UnitOfMeasure);
            ItemNoList.Add(POSSaleQuery.ItemNo);
            ItemDescList.Add(LocalItemDesc);
            MemberCardNoList.Add(POSSaleQuery.HeaderMemberCardNo);
            MemberContactNameList.Add(LocalMemberContactName);
            QtyList.Add(LocalQty);
            BaseQtyList.Add(LocalBaseQty);
            UnitPriceList.Add(LocalUnitPrice);
            AmountList.Add(LocalAmount);
            DiscountAmountList.Add(POSSaleQuery.DiscountAmount);
            TotalAmtList.Add(LocalAmount - POSSaleQuery.DiscountAmount);
            TransTypeList.Add(LocalTransType);
            CancelDocNoList.Add(LocalCancelDocNo);
            RefundDocNoList.Add(LocalRefundDocNo);
            RefRefundList.Add(POSSaleQuery.HeaderRefRefundReceiptNo);
            HeaderTimeList.Add(LocalTimeText);
        end;
        POSSaleQuery.Close();
    end;

    var
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        ItemTB: Record Item;
        POSTerminalTB: Record "LSC POS Terminal";
        MemberContactTB: Record "LSC Member Contact";
        RettailSetup: Record "LSC Retail Setup";
        TransHTb: Record "LSC Transaction Header";
        POSSaleQuery: Query "POSSaleByTerm_Q";

        VariantCodeList: List of [Code[10]];
        StoreNoList: List of [Code[20]];
        POSTerminalNoList: List of [Code[20]];
        ReceiptNoList: List of [Code[20]];
        DateTextList: List of [Text[50]];
        UOMList: List of [Code[10]];
        ItemNoList: List of [Code[20]];
        ItemDescList: List of [Text[100]];
        MemberCardNoList: List of [Code[20]];
        MemberContactNameList: List of [Text[100]];
        QtyList: List of [Decimal];
        BaseQtyList: List of [Decimal];
        UnitPriceList: List of [Decimal];
        AmountList: List of [Decimal];
        TotalAmtList: List of [Decimal];
        DiscountAmountList: List of [Decimal];
        TransTypeList: List of [Text[50]];
        CancelDocNoList: List of [Text[30]];
        RefundDocNoList: List of [Text[30]];
        RefRefundList: List of [Text[30]];
        HeaderTimeList: List of [Text[50]];

        ShowTime: Text[50];
        ShowDate: Text[50];
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        POSTerminalFilter: Code[20];
        PeriodDate: Text[100];
        ReportFilterText: Text[250];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        ShowVariantFlag: Boolean;
        RefundFilter: Option " ","Yes","No";
    // C-AVPWDLSVIP 03/07/2026 > Improve Performance of VIP Report(76075) - น้องปอ
}
