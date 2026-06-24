report 50403 "PLSR_Tot Offer Sales Item Pro"
{
    Caption = 'Total Offer Sales Item By Promotion';
    DefaultLayout = RDLC;
    RDLCLayout = './03 - Report Layout/Rep50403_TotalOfferSalesItemByPromotion.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Transaction Header"; "LSC Transaction Header")
        {
            DataItemTableView = sorting("Store No.", "POS Terminal No.", "Transaction No.")
                                where("Transaction Type" = CONST(Sales), "Entry Status" = FILTER(<> Voided));
            PrintOnlyIfDetail = true;

            dataitem("Trans. Discount Entry"; "LSC Trans. Discount Entry")
            {
                DataItemTableView = SORTING("Store No.", "POS Terminal No.", "Transaction No.", "Line No.", "Offer Type", "Offer No.")
                                    WHERE("Offer Type" = FILTER("Total Discount" | Coupon), "Discount Amount" = filter(<> 0));
                DataItemLink = "Transaction No." = FIELD("Transaction No."), "Store No." = FIELD("Store No."), "POS Terminal No." = FIELD("POS Terminal No.");

                trigger OnPreDataItem()
                begin
                    // โหลดเฉพาะ field ที่ใช้จริง
                    SetLoadFields("Offer No.", "Offer Type", "Discount Amount", "Line No.",
                                  "Store No.", "POS Terminal No.", "Transaction No.");
                    if OfferFilter <> '' then
                        SetFilter("Offer No.", OfferFilter);
                end;

                trigger OnAfterGetRecord()
                begin
                    LineNo += 1;
                    Clear(OfferNo);
                    Clear(DesPeriodicDiscount);
                    OfferNo := "Trans. Discount Entry"."Offer No.";

                    // Count Bill
                    Clear(CountBill);
                    CurrGroup := "Transaction Header"."Store No." + "Transaction Header"."POS Terminal No."
                                 + FORMAT("Transaction Header"."Transaction No.") + OfferNo;
                    IF (CurrGroup <> OldGroup) THEN
                        if "Trans. Discount Entry"."Discount Amount" <> 0 then
                            CountBill := 1;
                    OldGroup := CurrGroup;

                    // ── Cache PeriodicDisc / CouponHeader ──
                    // ถ้า OfferNo เดิม ไม่ต้อง GET ซ้ำ
                    IF "Trans. Discount Entry"."Offer Type" = "Trans. Discount Entry"."Offer Type"::"Total Discount" THEN BEGIN
                        if OfferNo <> LastPeriodicDiscNo then begin
                            CLEAR(PeriodicDiscTB);
                            PeriodicDiscTB.SetLoadFields(Description);
                            IF PeriodicDiscTB.GET(OfferNo) THEN;
                            LastPeriodicDiscNo := OfferNo;
                        end;
                        DesPeriodicDiscount := PeriodicDiscTB.Description;
                    END ELSE BEGIN
                        if OfferNo <> LastCouponNo then begin
                            CLEAR(CouponHeader);
                            CouponHeader.SetLoadFields(Description);
                            IF CouponHeader.GET(OfferNo) THEN;
                            LastCouponNo := OfferNo;
                        end;
                        DesPeriodicDiscount := CouponHeader.Description;
                    END;

                    CLEAR(ItemPrice);
                    CLEAR(LineQty);
                    CLEAR(LineAmount);
                    CLEAR(LineDiscAmount);
                    CLEAR(ItemNo);

                    // ── Cache TransSalesEntry ──
                    // Key = Store+Terminal+TransNo+LineNo — ไม่ค่อยซ้ำ GET ทุกครั้งก็ได้ แต่ใส่ SetLoadFields
                    CLEAR(TransSalesEntry);
                    TransSalesEntry.SetLoadFields("Item No.", "Store No.", "POS Terminal No.", "Transaction No.", "Line No.");
                    IF TransSalesEntry.GET("Trans. Discount Entry"."Store No.", "Trans. Discount Entry"."POS Terminal No.",
                                           "Trans. Discount Entry"."Transaction No.", "Trans. Discount Entry"."Line No.") THEN BEGIN

                        // ── Cache Barcodes ── (group by Item No.)
                        if TransSalesEntry."Item No." <> LastBarcodeItemNo then begin
                            CLEAR(BarcodesTB);
                            BarcodesTB.SETCURRENTKEY("Barcode No.");
                            BarcodesTB.SETRANGE("Item No.", TransSalesEntry."Item No.");
                            BarcodesTB.SetLoadFields("Barcode No.");
                            IF BarcodesTB.FINDFIRST() THEN;
                            LastBarcodeItemNo := TransSalesEntry."Item No.";
                        end;

                        // ── Cache Item ──
                        if TransSalesEntry."Item No." <> LastItemNo then begin
                            CLEAR(ItemTB);
                            ItemTB.SetLoadFields("No.", Description);
                            IF ItemTB.GET(TransSalesEntry."Item No.") THEN;
                            LastItemNo := TransSalesEntry."Item No.";
                        end;
                        ItemNo := ItemTB."No.";
                    END;

                    LineDiscAmount := "Trans. Discount Entry"."Discount Amount";
                    isBenefitItem := FALSE;
                    ShowLine := true;

                    CLEAR(BenefitsAmount);
                    CLEAR(BenefitsQty);

                    TempTransSalesEntry.Init();
                    TempTransSalesEntry."Receipt No." := "Transaction Header"."Receipt No.";
                    TempTransSalesEntry."Line No." := LineNo;
                    TempTransSalesEntry."Store No." := "Transaction Header"."Store No.";
                    TempTransSalesEntry."POS Terminal No." := "Transaction Header"."POS Terminal No.";
                    TempTransSalesEntry."Transaction No." := "Transaction Header"."Transaction No.";
                    TempTransSalesEntry."Promotion No." := OfferNo;
                    TempTransSalesEntry."Posting Exception Key" := DesPeriodicDiscount;
                    TempTransSalesEntry."Barcode No." := BarcodesTB."Barcode No.";
                    TempTransSalesEntry."Item No." := ItemNo;
                    TempTransSalesEntry."Item Number Scanned" := isBenefitItem;
                    TempTransSalesEntry."Item Description" := ItemTB.Description;
                    TempTransSalesEntry."Deal Header Line No." := CountBill;
                    TempTransSalesEntry."Net Amount" := LineAmount;
                    TempTransSalesEntry."Discount Amount" := LineDiscAmount;
                    TempTransSalesEntry."Standard Net Price" := BenefitsQty;
                    TempTransSalesEntry."Keyboard Item Entry" := ShowLine;
                    TempTransSalesEntry.Quantity := LineQty;
                    if TempTransSalesEntry.Insert() then;

                    TempCopyTransSalesEntry.Init();
                    TempCopyTransSalesEntry.Copy(TempTransSalesEntry);
                    if TempCopyTransSalesEntry.Insert() then;
                end;
            }

            dataitem("Trans. Disc. Benefit Entry"; "LSC Trans. Disc. Benefit Entry")
            {
                DataItemTableView = SORTING("Store No.", "POS Terminal No.", "Transaction No.", "Line No.")
                                        WHERE("Offer Type" = CONST("Total Discount"), Type = filter(Item | Coupon));
                DataItemLinkReference = "Transaction Header";
                DataItemLink = "Transaction No." = FIELD("Transaction No."), "Store No." = FIELD("Store No."), "POS Terminal No." = FIELD("POS Terminal No.");

                trigger OnPreDataItem()
                begin
                    SetLoadFields("Offer No.", "Offer Type", "No.", "Quantity", Value,
                                  "Store No.", "POS Terminal No.", "Transaction No.", "Line No.",
                                  "Variant Code", Type);
                    IF OfferFilter <> '' THEN
                        "Trans. Disc. Benefit Entry".SETRANGE("Offer No.", OfferFilter);
                end;

                trigger OnAfterGetRecord()
                var
                    TransDiscEntry: Record "LSC Trans. Discount Entry";
                begin
                    LineNo += 1;
                    CLEAR(OfferNo);
                    OfferNo := "Trans. Disc. Benefit Entry"."Offer No.";

                    // Count Bill
                    Clear(CountBill);
                    CurrGroupBenefit := "Transaction Header"."Store No." + "Transaction Header"."POS Terminal No."
                                        + FORMAT("Transaction Header"."Transaction No.") + OfferNo;
                    IF (CurrGroupBenefit <> OldGroupBenefit) THEN begin
                        Clear(TransDiscEntry);
                        TransDiscEntry.SetLoadFields("Store No.", "POS Terminal No.", "Transaction No.", "Offer No.", "Offer Type", "Discount Amount");
                        TransDiscEntry.SetRange("Store No.", "Store No.");
                        TransDiscEntry.SetRange("POS Terminal No.", "POS Terminal No.");
                        TransDiscEntry.SetRange("Transaction No.", "Transaction No.");
                        TransDiscEntry.SetFilter("Offer Type", '%1|%2', TransDiscEntry."Offer Type"::"Total Discount", TransDiscEntry."Offer Type"::Coupon);
                        TransDiscEntry.SetRange("Offer No.", "Offer No.");
                        TransDiscEntry.SetFilter("Discount Amount", '<>%1', 0);
                        if not TransDiscEntry.IsEmpty() then
                            CurrReport.Skip();
                        CountBill := 1;
                    end;
                    OldGroupBenefit := CurrGroupBenefit;

                    // ── Cache PeriodicDisc ──
                    if OfferNo <> LastPeriodicDiscNo then begin
                        CLEAR(PeriodicDiscTB);
                        PeriodicDiscTB.SetLoadFields(Description);
                        IF PeriodicDiscTB.GET(OfferNo) THEN;
                        LastPeriodicDiscNo := OfferNo;
                    end;

                    // ── Cache Barcodes ──
                    if "Trans. Disc. Benefit Entry"."No." <> LastBarcodeItemNo then begin
                        CLEAR(BarcodesTB);
                        BarcodesTB.SETCURRENTKEY("Barcode No.");
                        BarcodesTB.SETRANGE("Item No.", "Trans. Disc. Benefit Entry"."No.");
                        BarcodesTB.SetLoadFields("Barcode No.");
                        IF BarcodesTB.FINDFIRST() THEN;
                        LastBarcodeItemNo := "Trans. Disc. Benefit Entry"."No.";
                    end;

                    // ── Cache Item ──
                    if "Trans. Disc. Benefit Entry"."No." <> LastItemNo then begin
                        CLEAR(ItemTB);
                        ItemTB.SetLoadFields("No.", Description);
                        IF ItemTB.GET("Trans. Disc. Benefit Entry"."No.") THEN;
                        LastItemNo := "Trans. Disc. Benefit Entry"."No.";
                    end;
                    ItemNo := ItemTB."No.";

                    CLEAR(ItemPrice);
                    CLEAR(LineQty);
                    CLEAR(LineAmount);
                    CLEAR(LineDiscAmount);
                    ItemPrice := "Trans. Disc. Benefit Entry".Value;
                    LineQty := "Trans. Disc. Benefit Entry".Quantity;
                    LineAmount := "Trans. Disc. Benefit Entry".Quantity * "Trans. Disc. Benefit Entry".Value;
                    LineDiscAmount := 0;

                    isBenefitItem := TRUE;

                    CLEAR(BenefitsAmount);
                    BenefitsAmount := "Trans. Disc. Benefit Entry".Quantity * "Trans. Disc. Benefit Entry".Value;

                    CLEAR(BenefitsQty);
                    BenefitsQty := "Trans. Disc. Benefit Entry".Quantity;

                    Clear(ShowLine);
                    if Type = Type::Item then
                        ShowLine := true;

                    TempTransSalesEntry.Init();
                    TempTransSalesEntry."Receipt No." := "Transaction Header"."Receipt No.";
                    TempTransSalesEntry."Line No." := LineNo;
                    TempTransSalesEntry."Store No." := "Transaction Header"."Store No.";
                    TempTransSalesEntry."POS Terminal No." := "Transaction Header"."POS Terminal No.";
                    TempTransSalesEntry."Transaction No." := "Transaction Header"."Transaction No.";
                    TempTransSalesEntry."Promotion No." := OfferNo;
                    TempTransSalesEntry."Posting Exception Key" := PeriodicDiscTB.Description;
                    TempTransSalesEntry."Barcode No." := BarcodesTB."Barcode No.";
                    TempTransSalesEntry."Item No." := ItemNo;
                    TempTransSalesEntry."Item Number Scanned" := isBenefitItem;
                    TempTransSalesEntry."Item Description" := ItemTB.Description;
                    TempTransSalesEntry."Deal Header Line No." := CountBill;
                    TempTransSalesEntry."Net Amount" := LineAmount;
                    TempTransSalesEntry."Discount Amount" := LineDiscAmount;
                    TempTransSalesEntry."VAT Amount" := BenefitsAmount;
                    TempTransSalesEntry."Keyboard Item Entry" := ShowLine;
                    TempTransSalesEntry."Standard Net Price" := BenefitsQty;
                    TempTransSalesEntry.Price := ItemPrice;
                    TempTransSalesEntry.Quantity := LineQty;
                    TempTransSalesEntry."Variant Code" := "Trans. Disc. Benefit Entry"."Variant Code";
                    if TempTransSalesEntry.Insert() then;

                    TempCopyTransSalesEntry.Init();
                    TempCopyTransSalesEntry.Copy(TempTransSalesEntry);
                    if TempCopyTransSalesEntry.Insert() then;
                end;
            }

            trigger OnPreDataItem()
            begin
                // โหลดเฉพาะ field ที่ใช้จริงของ Transaction Header
                SetLoadFields("Store No.", "POS Terminal No.", "Transaction No.", "Receipt No.", Date);

                TempTransSalesEntry.Reset();
                TempTransSalesEntry.DeleteAll();
                TempCopyTransSalesEntry.Reset();
                TempCopyTransSalesEntry.DeleteAll();

                Clear(OldGroupBenefit);
                Clear(OldGroup);
                Clear(ShowLine);

                // Reset cache variables
                Clear(LastPeriodicDiscNo);
                Clear(LastCouponNo);
                Clear(LastBarcodeItemNo);
                Clear(LastItemNo);

                ComInfo.Get();
                RettailSetup.Get();

                IF Choose1Filter THEN BEGIN
                    DateFilter := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..'
                                  + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')
                                  + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                END ELSE
                    IF Choose2Filter THEN BEGIN
                        DateFilter := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    END;

                IF (StoreFilter <> '') THEN begin
                    "Transaction Header".SetFilter("Store No.", StoreFilter);
                    ReportFilterText += 'Store No : ' + FORMAT(StoreFilter + ' ');
                end;

                if DateFilter <> '' then
                    "Transaction Header".SetFilter(Date, DateFilter);

                ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                ShowTime := LSVIPRepFunction.AVTimeFormat(Time);

                if OfferFilter <> '' then
                    if ReportFilterText <> '' then
                        ReportFilterText += ',Promotion Filter No.: %1' + OfferFilter
                    else
                        ReportFilterText := 'Promotion Filter No.: %1' + OfferFilter;
            end;

            trigger OnPostDataItem()
            begin
                TempGroupStoreTransSalesEntry.Reset();
                TempGroupStoreTransSalesEntry.DeleteAll();
                Clear(StoreOfferCurr);
                Clear(StoreOfferOld);
                Clear(ItemCurr);
                Clear(ItemOld);
                TempTransSalesEntry.Reset();
                TempTransSalesEntry.SetCurrentKey("Store No.", "Promotion No.", "Item No.", "Item Number Scanned");
                if TempTransSalesEntry.FindSet() then
                    repeat
                        StoreOfferCurr := TempTransSalesEntry."Store No." + TempTransSalesEntry."Promotion No.";
                        ItemCurr := StoreOfferCurr + TempTransSalesEntry."Item No." + Format(TempTransSalesEntry."Item Number Scanned");
                        if StoreOfferCurr <> StoreOfferOld then begin
                            Clear(NewCountBill);
                            Clear(NewBenefitsQty);
                            Clear(NewLineAmount);
                            Clear(NewLineDiscAmount);
                            Clear(NewGrCountBill);
                            Clear(NewGrBenefitsQty);
                            Clear(NewGrLineAmount);
                            Clear(NewGrLineDiscAmount);
                            Clear(NewGrBenefitAmt);
                        end;

                        if ItemCurr <> ItemOld then begin
                            Clear(NewGrCountBill);
                            Clear(NewGrBenefitsQty);
                            Clear(NewGrLineAmount);
                            Clear(NewGrLineDiscAmount);
                            Clear(NewGrBenefitAmt);
                        end;

                        NewCountBill += TempTransSalesEntry."Deal Header Line No.";
                        NewBenefitsQty += TempTransSalesEntry."Standard Net Price";
                        NewLineAmount += TempTransSalesEntry."Net Amount";
                        NewLineDiscAmount += TempTransSalesEntry."Discount Amount";
                        NewBenefitAmt += TempTransSalesEntry."VAT Amount";

                        NewGrCountBill += TempTransSalesEntry."Deal Header Line No.";
                        NewGrBenefitsQty += TempTransSalesEntry."Standard Net Price";
                        NewGrLineAmount += TempTransSalesEntry."Net Amount";
                        NewGrLineDiscAmount += TempTransSalesEntry."Discount Amount";
                        NewGrBenefitAmt += TempTransSalesEntry."VAT Amount";

                        StoreOfferOld := StoreOfferCurr;
                        ItemOld := ItemCurr;

                        Clear(StoreOfferNew);
                        Clear(ItemNew);
                        TempCopyTransSalesEntry.Reset();
                        TempCopyTransSalesEntry.Copy(TempTransSalesEntry);
                        if TempCopyTransSalesEntry.Next() <> 0 then begin
                            StoreOfferNew := TempCopyTransSalesEntry."Store No." + TempCopyTransSalesEntry."Promotion No.";
                            ItemNew := StoreOfferNew + TempCopyTransSalesEntry."Item No." + Format(TempCopyTransSalesEntry."Item Number Scanned");
                        end;

                        if ItemCurr <> ItemNew then begin
                            TempGroupStoreTransSalesEntry.Init();
                            TempGroupStoreTransSalesEntry := TempTransSalesEntry;
                            TempGroupStoreTransSalesEntry."Deal Header Line No." := NewGrCountBill;
                            TempGroupStoreTransSalesEntry."Standard Net Price" := NewGrBenefitsQty;
                            TempGroupStoreTransSalesEntry."Net Amount" := NewGrLineAmount;
                            TempGroupStoreTransSalesEntry."Discount Amount" := NewGrLineDiscAmount;
                            TempGroupStoreTransSalesEntry."VAT Amount" := NewGrBenefitAmt;
                            if TempGroupStoreTransSalesEntry.Insert() then;
                        end;

                        if StoreOfferCurr <> StoreOfferNew then begin
                            TempGroupStoreTransSalesEntry.Init();
                            TempGroupStoreTransSalesEntry := TempTransSalesEntry;
                            TempGroupStoreTransSalesEntry."Deal Header Line No." := NewCountBill;
                            TempGroupStoreTransSalesEntry."Standard Net Price" := NewBenefitsQty;
                            TempGroupStoreTransSalesEntry."Net Amount" := NewLineAmount;
                            TempGroupStoreTransSalesEntry."Discount Amount" := NewLineDiscAmount;
                            TempGroupStoreTransSalesEntry."VAT Amount" := NewBenefitAmt;
                            if TempGroupStoreTransSalesEntry.Insert() then;
                        end;
                    until TempTransSalesEntry.Next() = 0;
            end;
        }

        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) WHERE(Number = FILTER(1 ..));
            column(Name_ComInfo; ComInfo.Name) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(PeriodDate; PeriodDate) { }
            column(ReportFilterText; ReportFilterText) { }
            column(StoreNo_TransactionHeader; TempGroupStoreTransSalesEntry."Store No.") { }
            column(Receipt_No_; TempGroupStoreTransSalesEntry."Receipt No.") { }
            column(OfferNo; TempGroupStoreTransSalesEntry."Promotion No.") { }
            column(CountBill; TempGroupStoreTransSalesEntry."Deal Header Line No.") { }
            column(Description_PeriodicDiscount; TempGroupStoreTransSalesEntry."Posting Exception Key") { }
            column(ItemNo_TransSalesEntry; TempGroupStoreTransSalesEntry."Item No.") { }
            column(BarcodeNo_TransSaleEntry; TempGroupStoreTransSalesEntry."Barcode No.") { }
            column(ItemDescription_TransSalesEntry; TempGroupStoreTransSalesEntry."Item Description") { }
            column(Price_TransSalesEntry; TempGroupStoreTransSalesEntry.Price) { }
            column(LineQty; TempGroupStoreTransSalesEntry.Quantity) { }
            column(LineAmount; TempGroupStoreTransSalesEntry."Net Amount") { }
            column(LineDiscountAmount; TempGroupStoreTransSalesEntry."Discount Amount") { }
            column(isBenefitItem; TempGroupStoreTransSalesEntry."Item Number Scanned") { }
            column(BenefitsQty; TempGroupStoreTransSalesEntry."Standard Net Price") { }
            column(BenefitsAmount; TempGroupStoreTransSalesEntry."VAT Amount") { }
            column(ShowVariant; not RettailSetup."PLSPOS_Show Var for Report VIP") { }
            column(ShowLine; TempGroupStoreTransSalesEntry."Keyboard Item Entry") { }
            column(Discount_Amount; TempGroupStoreTransSalesEntry."Discount Amount") { }
            column(Variant_Code; TempGroupStoreTransSalesEntry."Variant Code") { }

            trigger OnPreDataItem()
            begin
                TempGroupStoreTransSalesEntry.Reset();
            end;

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if NOT TempGroupStoreTransSalesEntry.find('-') then
                        CurrReport.Break();
                end else
                    if TempGroupStoreTransSalesEntry.Next() = 0 then
                        CurrReport.Break();
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
                        field("Promotion No. :"; OfferFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = "LSC Periodic Discount"."No." where("Offer Type" = filter("Total Discount"));
                            Caption = 'Promotion No. :';
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
        end;
    }

    var
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        CouponHeader: Record "LSC Coupon Header";
        PeriodicDiscTB: Record "LSC Periodic Discount";
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        BarcodesTB: Record "LSC Barcodes";
        ItemTB: Record Item;
        RettailSetup: Record "LSC Retail Setup";

        // Cache variables — เก็บ key ล่าสุดที่ GET ไปแล้ว ไม่ต้อง GET ซ้ำถ้า key เดิม
        LastPeriodicDiscNo: Code[20];
        LastCouponNo: Code[20];
        LastBarcodeItemNo: Code[20];
        LastItemNo: Code[20];

        ReportFilterText: Text;
        PeriodDate: Text[100];
        OfferFilter: Text[100];
        ShowDate: Text[50];
        ShowTime: Text[50];
        OfferNo: Code[30];
        ItemNo: Code[20];
        ItemPrice: Decimal;
        LineQty: Decimal;
        LineAmount: Decimal;
        LineDiscAmount: Decimal;
        IsBenefitItem: Boolean;
        CountBill: Integer;
        BenefitsAmount: Decimal;
        BenefitsQty: Decimal;
        CurrGroup: Text[250];
        OldGroup: Text[250];
        DesPeriodicDiscount: Text[100];
        FDateFilter: Date;
        FromDateFilter: Date;
        TodateFilter: Date;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        StoreFilter: Code[20];
        DateFilter: Text[100];
        CurrGroupBenefit: Text[250];
        OldGroupBenefit: Text[250];
        ShowLine: Boolean;
        TempTransSalesEntry: Record "LSC Trans. Sales Entry" temporary;
        TempCopyTransSalesEntry: Record "LSC Trans. Sales Entry" temporary;
        TempGroupStoreTransSalesEntry: Record "LSC Trans. Sales Entry" temporary;
        LineNo: Integer;
        StoreOfferCurr: Text[100];
        StoreOfferOld: Text[100];
        StoreOfferNew: Text[100];
        ItemCurr: Text[100];
        ItemOld: Text[100];
        ItemNew: Text[100];
        NewCountBill: Integer;
        NewBenefitsQty: Decimal;
        NewLineAmount: Decimal;
        NewLineDiscAmount: Decimal;
        NewGrCountBill: Integer;
        NewGrBenefitsQty: Decimal;
        NewGrLineAmount: Decimal;
        NewGrLineDiscAmount: Decimal;
        NewBenefitAmt: Decimal;
        NewGrBenefitAmt: Decimal;
}
