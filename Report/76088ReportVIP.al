report 50108 "Tot Offer Sales Item Pro"
{
    Caption = 'Total Offer Sales Item By Promotion';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50108_TotalOfferSalesItemByPromotion.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Transaction Header"; "LSC Transaction Header")
        {
            DataItemTableView = sorting("Store No.", "POS Terminal No.", "Transaction No.")
                                where("Transaction Type" = CONST(Sales), "Entry Status" = FILTER(<> Voided));
            PrintOnlyIfDetail = true;

            // ── dummy dataitem 1: ไม่วน loop จริง BC ต้องการให้ประกาศไว้ ──
            dataitem("Trans. Discount Entry"; "LSC Trans. Discount Entry")
            {
                DataItemLink = "Transaction No." = FIELD("Transaction No."),
                               "Store No." = FIELD("Store No."),
                               "POS Terminal No." = FIELD("POS Terminal No.");
                DataItemTableView = WHERE("Offer Type" = FILTER("Total Discount" | Coupon),
                                         "Discount Amount" = filter(<> 0));
                trigger OnPreDataItem()
                begin
                    CurrReport.Break();
                end;
            }

            // ── dummy dataitem 2 ──
            dataitem("Trans. Disc. Benefit Entry"; "LSC Trans. Disc. Benefit Entry")
            {
                DataItemLinkReference = "Transaction Header";
                DataItemLink = "Transaction No." = FIELD("Transaction No."),
                               "Store No." = FIELD("Store No."),
                               "POS Terminal No." = FIELD("POS Terminal No.");
                DataItemTableView = WHERE("Offer Type" = CONST("Total Discount"),
                                         Type = filter(Item | Coupon));
                trigger OnPreDataItem()
                begin
                    CurrReport.Break();
                end;
            }

            trigger OnPreDataItem()
            begin
                SetLoadFields("Store No.", "POS Terminal No.", "Transaction No.", "Receipt No.", Date);

                TempTransSalesEntry.Reset();
                TempTransSalesEntry.DeleteAll();
                TempCopyTransSalesEntry.Reset();
                TempCopyTransSalesEntry.DeleteAll();

                Clear(OldGroupBenefit);
                Clear(OldGroup);
                Clear(ShowLine);
                Clear(LastCouponNo);
                Clear(LastPeriodicDiscNo);

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

                IF StoreFilter <> '' THEN begin
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

            trigger OnAfterGetRecord()
            begin
                // ── Process Trans. Discount Entry ผ่าน Query ──
                DiscQ.SetFilter(StoreFilter, "Transaction Header"."Store No.");
                DiscQ.SetFilter(PosTerminalNoFilter, "Transaction Header"."POS Terminal No.");
                DiscQ.SetFilter(TransactionNoFilter, Format("Transaction Header"."Transaction No."));
                if OfferFilter <> '' then
                    DiscQ.SetFilter(OfferNoFilter, OfferFilter);
                DiscQ.Open();

                while DiscQ.Read() do begin
                    if DiscQ.Discount_Amount_ <> 0 then begin
                        LineNo += 1;
                        OfferNo := DiscQ.Offer_No_;

                        Clear(CountBill);
                        CurrGroup := DiscQ.Store_No_ + DiscQ.POS_Terminal_No_
                                     + FORMAT(DiscQ.Transaction_No_) + OfferNo;
                        if CurrGroup <> OldGroup then
                            CountBill := 1;
                        OldGroup := CurrGroup;

                        // Periodic Disc Description จาก Query JOIN
                        // Coupon Description ยังใช้ Cache (ไม่ JOIN เพราะ PK ไม่แน่ใจ)
                        if DiscQ.Offer_Type_ = DiscQ.Offer_Type_::"Total Discount" then
                            DesPeriodicDiscount := DiscQ.Periodic_Disc_Description
                        else begin
                            // Cache CouponHeader
                            if OfferNo <> LastCouponNo then begin
                                Clear(CouponHeader);
                                if CouponHeader.Get(OfferNo) then;
                                LastCouponNo := OfferNo;
                            end;
                            DesPeriodicDiscount := CouponHeader.Description;
                        end;

                        TempTransSalesEntry.Init();
                        TempTransSalesEntry."Receipt No." := "Transaction Header"."Receipt No.";
                        TempTransSalesEntry."Line No." := LineNo;
                        TempTransSalesEntry."Store No." := "Transaction Header"."Store No.";
                        TempTransSalesEntry."POS Terminal No." := "Transaction Header"."POS Terminal No.";
                        TempTransSalesEntry."Transaction No." := "Transaction Header"."Transaction No.";
                        TempTransSalesEntry."Promotion No." := OfferNo;
                        TempTransSalesEntry."Posting Exception Key" := DesPeriodicDiscount;
                        TempTransSalesEntry."Barcode No." := DiscQ.Barcode_No_;
                        TempTransSalesEntry."Item No." := DiscQ.Item_No_;
                        TempTransSalesEntry."Item Number Scanned" := false;
                        TempTransSalesEntry."POS Line Description" := DiscQ.Item_Description;
                        TempTransSalesEntry."Deal Header Line No." := CountBill;
                        TempTransSalesEntry."Net Amount" := 0;
                        TempTransSalesEntry."Discount Amount" := DiscQ.Discount_Amount_;
                        TempTransSalesEntry."Standard Net Price" := 0;
                        TempTransSalesEntry."Keyboard Item Entry" := true;
                        TempTransSalesEntry.Quantity := 0;
                        if TempTransSalesEntry.Insert() then;

                        TempCopyTransSalesEntry.Init();
                        TempCopyTransSalesEntry.Copy(TempTransSalesEntry);
                        if TempCopyTransSalesEntry.Insert() then;
                    end;
                end;
                DiscQ.Close();

                // ── Process Trans. Disc. Benefit Entry ผ่าน Query ──
                BenefitQ.SetFilter(StoreFilter, "Transaction Header"."Store No.");
                BenefitQ.SetFilter(PosTerminalNoFilter, "Transaction Header"."POS Terminal No.");
                BenefitQ.SetFilter(TransactionNoFilter, Format("Transaction Header"."Transaction No."));
                if OfferFilter <> '' then
                    BenefitQ.SetFilter(OfferNoFilter, OfferFilter);
                BenefitQ.Open();

                while BenefitQ.Read() do begin
                    // Cache IsEmpty() check ต่อ CurrGroupBenefit
                    CurrGroupBenefit := BenefitQ.Store_No_ + BenefitQ.POS_Terminal_No_
                                        + FORMAT(BenefitQ.Transaction_No_) + BenefitQ.Offer_No_;
                    if CurrGroupBenefit <> OldGroupBenefit then begin
                        Clear(TransDiscChk);
                        TransDiscChk.SetLoadFields("Store No.", "POS Terminal No.", "Transaction No.", "Offer No.", "Offer Type", "Discount Amount");
                        TransDiscChk.SetRange("Store No.", BenefitQ.Store_No_);
                        TransDiscChk.SetRange("POS Terminal No.", BenefitQ.POS_Terminal_No_);
                        TransDiscChk.SetRange("Transaction No.", BenefitQ.Transaction_No_);
                        TransDiscChk.SetFilter("Offer Type", '%1|%2',
                            TransDiscChk."Offer Type"::"Total Discount",
                            TransDiscChk."Offer Type"::Coupon);
                        TransDiscChk.SetRange("Offer No.", BenefitQ.Offer_No_);
                        TransDiscChk.SetFilter("Discount Amount", '<>%1', 0);
                        BenefitHasDisc := not TransDiscChk.IsEmpty();
                        OldGroupBenefit := CurrGroupBenefit;
                    end;

                    if not BenefitHasDisc then begin
                        LineNo += 1;
                        OfferNo := BenefitQ.Offer_No_;

                        Clear(CountBill);
                        if CurrGroupBenefit <> OldGroupBenefit then
                            CountBill := 1;

                        TempTransSalesEntry.Init();
                        TempTransSalesEntry."Receipt No." := "Transaction Header"."Receipt No.";
                        TempTransSalesEntry."Line No." := LineNo;
                        TempTransSalesEntry."Store No." := "Transaction Header"."Store No.";
                        TempTransSalesEntry."POS Terminal No." := "Transaction Header"."POS Terminal No.";
                        TempTransSalesEntry."Transaction No." := "Transaction Header"."Transaction No.";
                        TempTransSalesEntry."Promotion No." := OfferNo;
                        TempTransSalesEntry."Posting Exception Key" := BenefitQ.Periodic_Disc_Description;
                        TempTransSalesEntry."Barcode No." := BenefitQ.Barcode_No_;
                        TempTransSalesEntry."Item No." := BenefitQ.No_;
                        TempTransSalesEntry."Item Number Scanned" := true;
                        TempTransSalesEntry."POS Line Description" := BenefitQ.Item_Description;
                        TempTransSalesEntry."Deal Header Line No." := CountBill;
                        TempTransSalesEntry."Net Amount" := BenefitQ.Quantity_ * BenefitQ.Value_;
                        TempTransSalesEntry."Discount Amount" := 0;
                        TempTransSalesEntry."VAT Amount" := BenefitQ.Quantity_ * BenefitQ.Value_;
                        TempTransSalesEntry."Keyboard Item Entry" := BenefitQ.Type_ = BenefitQ.Type_::Item;
                        TempTransSalesEntry."Standard Net Price" := BenefitQ.Quantity_;
                        TempTransSalesEntry.Price := BenefitQ.Value_;
                        TempTransSalesEntry.Quantity := BenefitQ.Quantity_;
                        TempTransSalesEntry."Variant Code" := BenefitQ.Variant_Code_;
                        if TempTransSalesEntry.Insert() then;

                        TempCopyTransSalesEntry.Init();
                        TempCopyTransSalesEntry.Copy(TempTransSalesEntry);
                        if TempCopyTransSalesEntry.Insert() then;
                    end;
                end;
                BenefitQ.Close();
            end;

            trigger OnPostDataItem()
            var
                SavedRec: Record "LSC Trans. Sales Entry" temporary;
                NextStoreOffer: Text[100];
                NextItem: Text[100];
                PrevStoreOffer: Text[100];
                PrevItem: Text[100];
            begin
                TempGroupStoreTransSalesEntry.Reset();
                TempGroupStoreTransSalesEntry.DeleteAll();

                TempTransSalesEntry.Reset();
                TempTransSalesEntry.SetCurrentKey("Store No.", "Promotion No.", "Item No.", "Item Number Scanned");

                if not TempTransSalesEntry.FindSet() then
                    exit;

                PrevStoreOffer := '';
                PrevItem := '';
                Clear(NewCountBill);
                Clear(NewBenefitsQty);
                Clear(NewLineAmount);
                Clear(NewLineDiscAmount);
                Clear(NewBenefitAmt);
                Clear(NewGrCountBill);
                Clear(NewGrBenefitsQty);
                Clear(NewGrLineAmount);
                Clear(NewGrLineDiscAmount);
                Clear(NewGrBenefitAmt);

                repeat
                    StoreOfferCurr := TempTransSalesEntry."Store No." + TempTransSalesEntry."Promotion No.";
                    ItemCurr := StoreOfferCurr + TempTransSalesEntry."Item No."
                                + Format(TempTransSalesEntry."Item Number Scanned");

                    if StoreOfferCurr <> PrevStoreOffer then begin
                        Clear(NewCountBill);
                        Clear(NewBenefitsQty);
                        Clear(NewLineAmount);
                        Clear(NewLineDiscAmount);
                        Clear(NewBenefitAmt);
                        Clear(NewGrCountBill);
                        Clear(NewGrBenefitsQty);
                        Clear(NewGrLineAmount);
                        Clear(NewGrLineDiscAmount);
                        Clear(NewGrBenefitAmt);
                    end else
                        if ItemCurr <> PrevItem then begin
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

                    SavedRec := TempTransSalesEntry;
                    PrevStoreOffer := StoreOfferCurr;
                    PrevItem := ItemCurr;

                    // peek ถัดไปโดย Next() ตรงๆ — ไม่ต้อง Copy
                    if TempTransSalesEntry.Next() <> 0 then begin
                        NextStoreOffer := TempTransSalesEntry."Store No." + TempTransSalesEntry."Promotion No.";
                        NextItem := NextStoreOffer + TempTransSalesEntry."Item No."
                                    + Format(TempTransSalesEntry."Item Number Scanned");
                    end else begin
                        NextStoreOffer := '';
                        NextItem := '';
                    end;

                    if ItemCurr <> NextItem then begin
                        TempGroupStoreTransSalesEntry.Init();
                        TempGroupStoreTransSalesEntry := SavedRec;
                        TempGroupStoreTransSalesEntry."Deal Header Line No." := NewGrCountBill;
                        TempGroupStoreTransSalesEntry."Standard Net Price" := NewGrBenefitsQty;
                        TempGroupStoreTransSalesEntry."Net Amount" := NewGrLineAmount;
                        TempGroupStoreTransSalesEntry."Discount Amount" := NewGrLineDiscAmount;
                        TempGroupStoreTransSalesEntry."VAT Amount" := NewGrBenefitAmt;
                        if TempGroupStoreTransSalesEntry.Insert() then;
                    end;

                    if StoreOfferCurr <> NextStoreOffer then begin
                        TempGroupStoreTransSalesEntry.Init();
                        TempGroupStoreTransSalesEntry := SavedRec;
                        TempGroupStoreTransSalesEntry."Deal Header Line No." := NewCountBill;
                        TempGroupStoreTransSalesEntry."Standard Net Price" := NewBenefitsQty;
                        TempGroupStoreTransSalesEntry."Net Amount" := NewLineAmount;
                        TempGroupStoreTransSalesEntry."Discount Amount" := NewLineDiscAmount;
                        TempGroupStoreTransSalesEntry."VAT Amount" := NewBenefitAmt;
                        if TempGroupStoreTransSalesEntry.Insert() then;
                    end;

                until NextStoreOffer = '';
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
            column(ItemDescription_TransSalesEntry; TempGroupStoreTransSalesEntry."POS Line Description") { }
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
        RettailSetup: Record "LSC Retail Setup";
        TransDiscChk: Record "LSC Trans. Discount Entry";

        DiscQ: Query "PLSR_TransDiscount Q";
        BenefitQ: Query "PLSR_TransBenefit Q";

        // Cache
        LastCouponNo: Code[20];
        LastPeriodicDiscNo: Code[20];
        BenefitHasDisc: Boolean;

        TempTransSalesEntry: Record "LSC Trans. Sales Entry" temporary;
        TempCopyTransSalesEntry: Record "LSC Trans. Sales Entry" temporary;
        TempGroupStoreTransSalesEntry: Record "LSC Trans. Sales Entry" temporary;

        ReportFilterText: Text;
        PeriodDate: Text[100];
        OfferFilter: Text[100];
        ShowDate: Text[50];
        ShowTime: Text[50];
        OfferNo: Code[30];
        CountBill: Integer;
        DesPeriodicDiscount: Text[100];
        FDateFilter: Date;
        FromDateFilter: Date;
        TodateFilter: Date;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        StoreFilter: Code[20];
        DateFilter: Text[100];
        CurrGroup: Text[250];
        OldGroup: Text[250];
        CurrGroupBenefit: Text[250];
        OldGroupBenefit: Text[250];
        ShowLine: Boolean;
        LineNo: Integer;
        StoreOfferCurr: Text[100];
        ItemCurr: Text[100];
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
