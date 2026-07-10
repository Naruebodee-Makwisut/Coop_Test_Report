report 50115 "PLSR_Sales_Report by Item"
{
    Caption = 'POS Sales Report by Item';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50115_POSSalesReportByItem.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem(Line; Integer)
        {
            DataItemTableView = sorting(Number);

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
            column(Item_No_TransSale; CurrItemNo)
            { }
            column(Item_Name_ItemTB; CurrItemDesc)
            { }
            column(Unit_of_Measure; CurrUOM)
            { }
            column(Qty_TransSale; CurrLineQty)
            { }
            column(Price_TransSale; CurrPriceTransSale)
            { }
            column(Amount_TransSale; CurrLineAmount)
            { }
            column(Discount_Amount_TransSale; CurrLineDiscountAmount)
            { }
            column(TotalAmt; CurrLineTotalAmount)
            { }
            column(SumQty; SumQty)
            { }
            column(SumAmount; SumAmount)
            { }
            column(SumTotalAmount; SumTotalAmount)
            { }
            column(ShowQtyZero; ShowQtyZero)
            { }
            column(LinePercent_Qty; CurrLinePercentQty)
            { }
            column(LinePercent_Amount; CurrLinePercentAmount)
            { }
            column(LinePercent_TotalAmount; CurrLinePercentTotalAmount)
            { }

            trigger OnPreDataItem()
            begin
                IF Choose1Filter THEN BEGIN
                    DateFilter := FORMAT(FromDateFilter) + '..' + FORMAT(TodateFilter);
                    PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter) + ' ถึง ' + FORMAT(TodateFilter);
                END
                ELSE
                    IF Choose2Filter THEN BEGIN
                        DateFilter := FORMAT(FDateFilter);
                        PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter);
                    END;

                IF (StoreFilter <> '') THEN
                    ReportFilterText += 'Store No : ' + FORMAT(StoreFilter + ' ');
                IF (ItemNoFilter <> '') THEN
                    ReportFilterText += ' Item No: ' + FORMAT(ItemNoFilter + ' ');

                // Grand totals: one SQL aggregate, independent of the ShowQtyZero line filter
                CalculateGrandTotals();

                // One query round trip (SQL-side GROUP BY) instead of one CalcSums per
                // Item/UOM/Price group, then build the render lists fully in memory
                PrecomputeRowData();

                if RenderItemNo.Count = 0 then
                    SetRange(Number, 0, 0)
                else
                    SetRange(Number, 1, RenderItemNo.Count);
            end;

            trigger OnAfterGetRecord()
            begin
                // Pure array/list lookups - zero DB calls, zero computation per rendered row
                CurrItemNo := RenderItemNo.Get(Number);
                CurrUOM := RenderUOM.Get(Number);
                CurrItemDesc := RenderItemDesc.Get(Number);
                CurrLineQty := RenderLineQty.Get(Number);
                CurrPriceTransSale := RenderPriceTransSale.Get(Number);
                CurrLineAmount := RenderLineAmount.Get(Number);
                CurrLineDiscountAmount := RenderLineDiscountAmount.Get(Number);
                CurrLineTotalAmount := RenderLineTotalAmount.Get(Number);
                CurrLinePercentQty := RenderLinePercentQty.Get(Number);
                CurrLinePercentAmount := RenderLinePercentAmount.Get(Number);
                CurrLinePercentTotalAmount := RenderLinePercentTotalAmount.Get(Number);
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
                        field("Show Quantity Zero :"; ShowQtyZero)
                        {
                            ApplicationArea = All;
                            Caption = 'Show Quantity Zero :';
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
        ShowTime: Text[50];
        ShowDate: Text[50];
        DateFilter: Text[100];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        SumQty: Decimal;
        SumAmount: Decimal;
        SumTotalAmount: Decimal;
        ShowQtyZero: Boolean;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;

        // Precomputed render lists - one entry per output line, built once in PrecomputeRowData()
        RenderItemNo: List of [Code[20]];
        RenderUOM: List of [Code[10]];
        RenderItemDesc: List of [Text[250]];
        RenderLineQty: List of [Decimal];
        RenderPriceTransSale: List of [Decimal];
        RenderLineAmount: List of [Decimal];
        RenderLineDiscountAmount: List of [Decimal];
        RenderLineTotalAmount: List of [Decimal];
        RenderLinePercentQty: List of [Decimal];
        RenderLinePercentAmount: List of [Decimal];
        RenderLinePercentTotalAmount: List of [Decimal];

        // Scalars for the row currently being rendered
        CurrItemNo: Code[20];
        CurrUOM: Code[10];
        CurrItemDesc: Text[250];
        CurrLineQty: Decimal;
        CurrPriceTransSale: Decimal;
        CurrLineAmount: Decimal;
        CurrLineDiscountAmount: Decimal;
        CurrLineTotalAmount: Decimal;
        CurrLinePercentQty: Decimal;
        CurrLinePercentAmount: Decimal;
        CurrLinePercentTotalAmount: Decimal;

    local procedure CalculateGrandTotals()
    var
        TransSaleEntryTB: Record "LSC Trans. Sales Entry";
    begin
        IF DateFilter <> '' THEN
            TransSaleEntryTB.SETFILTER(Date, DateFilter);
        IF StoreFilter <> '' THEN
            TransSaleEntryTB.SETFILTER("Store No.", StoreFilter);
        IF ItemNoFilter <> '' THEN
            TransSaleEntryTB.SETFILTER("Item No.", ItemNoFilter);

        TransSaleEntryTB.CalcSums(Quantity, "Total Rounded Amt.", "Discount Amount");
        SumQty := -TransSaleEntryTB.Quantity;
        SumAmount := -TransSaleEntryTB."Total Rounded Amt." + TransSaleEntryTB."Discount Amount";
        SumTotalAmount := -TransSaleEntryTB."Total Rounded Amt.";
    end;

    local procedure PrecomputeRowData()
    var
        SalesQuery: Query "PLSR_Sales By Item";
        ItemRec: Record Item;
        GroupKeys: List of [Text];
        ItemNoOfKey: Dictionary of [Text, Code[20]];
        UOMOfKey: Dictionary of [Text, Code[10]];
        PriceOfKey: Dictionary of [Text, Decimal];
        QtyByKey: Dictionary of [Text, Decimal];
        DiscAmtByKey: Dictionary of [Text, Decimal];
        TotalAmtByKey: Dictionary of [Text, Decimal];
        UOMQtyByKey: Dictionary of [Text, Decimal];
        FirstUOMPriceByKey: Dictionary of [Text, Decimal];
        GroupKey: Text;
        LastItemNo: Code[20];
        LastItemDesc: Text[250];
        LQty: Decimal;
        LPrice: Decimal;
        LAmount: Decimal;
        LDiscAmount: Decimal;
        LTotalAmount: Decimal;
        i: Integer;
    begin
        IF DateFilter <> '' THEN
            SalesQuery.SetFilter(TransDate, DateFilter);
        IF StoreFilter <> '' THEN
            SalesQuery.SetFilter(Store_No, StoreFilter);
        IF ItemNoFilter <> '' THEN
            SalesQuery.SetFilter(Item_No, ItemNoFilter);

        SalesQuery.Open();
        while SalesQuery.Read() do begin
            GroupKey := SalesQuery.Item_No + '|' + SalesQuery.UOM + '|' + Format(SalesQuery.Price, 0, 9);
            if not GroupKeys.Contains(GroupKey) then begin
                GroupKeys.Add(GroupKey);
                ItemNoOfKey.Add(GroupKey, SalesQuery.Item_No);
                UOMOfKey.Add(GroupKey, SalesQuery.UOM);
                PriceOfKey.Add(GroupKey, SalesQuery.Price);
                QtyByKey.Add(GroupKey, 0);
                DiscAmtByKey.Add(GroupKey, 0);
                TotalAmtByKey.Add(GroupKey, 0);
                UOMQtyByKey.Add(GroupKey, 0);
                FirstUOMPriceByKey.Add(GroupKey, SalesQuery.UOM_Price);
            end;
            // Re-aggregate across Date/Store in memory - no DB calls here, just arithmetic
            QtyByKey.Set(GroupKey, QtyByKey.Get(GroupKey) + SalesQuery.Sum_Quantity);
            DiscAmtByKey.Set(GroupKey, DiscAmtByKey.Get(GroupKey) + SalesQuery.Sum_DiscountAmount);
            TotalAmtByKey.Set(GroupKey, TotalAmtByKey.Get(GroupKey) + SalesQuery.Sum_TotalRoundedAmt);
            UOMQtyByKey.Set(GroupKey, UOMQtyByKey.Get(GroupKey) + SalesQuery.Sum_UOMQuantity);
        end;
        SalesQuery.Close();

        // Phase 2: build the final render lists (ShowQtyZero filter + % calc), in the same
        // ascending Item/UOM/Price order the query returned (GroupKeys preserves first-seen order)
        Clear(RenderItemNo);
        Clear(RenderUOM);
        Clear(RenderItemDesc);
        Clear(RenderLineQty);
        Clear(RenderPriceTransSale);
        Clear(RenderLineAmount);
        Clear(RenderLineDiscountAmount);
        Clear(RenderLineTotalAmount);
        Clear(RenderLinePercentQty);
        Clear(RenderLinePercentAmount);
        Clear(RenderLinePercentTotalAmount);

        Clear(LastItemNo);
        for i := 1 to GroupKeys.Count do begin
            GroupKey := GroupKeys.Get(i);

            if UOMQtyByKey.Get(GroupKey) <> 0 then
                LQty := -UOMQtyByKey.Get(GroupKey)
            else
                LQty := -QtyByKey.Get(GroupKey);

            if not ((not ShowQtyZero) and (LQty = 0)) then begin
                if FirstUOMPriceByKey.Get(GroupKey) <> 0 then
                    LPrice := FirstUOMPriceByKey.Get(GroupKey)
                else
                    LPrice := PriceOfKey.Get(GroupKey);

                LAmount := -TotalAmtByKey.Get(GroupKey) + DiscAmtByKey.Get(GroupKey);
                LDiscAmount := DiscAmtByKey.Get(GroupKey);
                LTotalAmount := -TotalAmtByKey.Get(GroupKey);

                // Item lookup cached per distinct Item No. - same cardinality as before,
                // just now driven off the grouped keys instead of the raw dataitem loop
                if ItemNoOfKey.Get(GroupKey) <> LastItemNo then begin
                    LastItemNo := ItemNoOfKey.Get(GroupKey);
                    Clear(ItemRec);
                    ItemRec.SetLoadFields(Description, "Description 2");
                    if ItemRec.Get(LastItemNo) then
                        LastItemDesc := ItemRec.Description + ' ' + ItemRec."Description 2"
                    else
                        LastItemDesc := '';
                end;

                RenderItemNo.Add(ItemNoOfKey.Get(GroupKey));
                RenderUOM.Add(UOMOfKey.Get(GroupKey));
                RenderItemDesc.Add(LastItemDesc);
                RenderLineQty.Add(LQty);
                RenderPriceTransSale.Add(LPrice);
                RenderLineAmount.Add(LAmount);
                RenderLineDiscountAmount.Add(LDiscAmount);
                RenderLineTotalAmount.Add(LTotalAmount);

                if LQty <> 0 then
                    RenderLinePercentQty.Add(Round((LQty / SumQty) * 100, 0.01, '='))
                else
                    RenderLinePercentQty.Add(0);
                if LAmount <> 0 then
                    RenderLinePercentAmount.Add(Round((LAmount / SumAmount) * 100, 0.01, '='))
                else
                    RenderLinePercentAmount.Add(0);
                if LTotalAmount <> 0 then
                    RenderLinePercentTotalAmount.Add(Round((LTotalAmount / SumTotalAmount) * 100, 0.01, '='))
                else
                    RenderLinePercentTotalAmount.Add(0);
            end;
        end;
    end;
<<<<<<< HEAD
}
=======
}
>>>>>>> 86fc5bd8419c66e46c63d768502f437bd6b59ca7
