report 50108 "PLSR_Tot_Offer Sales Item Pro"
{
    Caption = 'Total Offer Sales Item By Promotion';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep76088_TotalOfferSalesItemByPromotion.rdl';
    PreviewMode = PrintLayout;

    // AVPWDLSVIP 01/07/2026 > Improve Performance of VIP Report(76088) - น้องปอ
    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) WHERE(Number = FILTER(1 ..));
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
            column(StoreNo_TransactionHeader; TempGroupStoreTransSalesEntry."Store No.")
            { }
            column(Receipt_No_; TempGroupStoreTransSalesEntry."Receipt No.")
            { }
            column(OfferNo; TempGroupStoreTransSalesEntry."Promotion No.")
            { }
            column(CountBill; TempGroupStoreTransSalesEntry."Deal Header Line No.")
            { }
            column(Description_PeriodicDiscount; TempGroupStoreTransSalesEntry."Posting Exception Key")
            { }
            column(ItemNo_TransSalesEntry; TempGroupStoreTransSalesEntry."Item No.")
            { }
            column(BarcodeNo_TransSaleEntry; TempGroupStoreTransSalesEntry."Barcode No.")
            { }
            column(ItemDescription_TransSalesEntry; TempGroupStoreTransSalesEntry."POS Line Description")
            { }
            column(Price_TransSalesEntry; TempGroupStoreTransSalesEntry.Price)
            { }
            column(LineQty; TempGroupStoreTransSalesEntry.Quantity)
            { }
            column(LineAmount; TempGroupStoreTransSalesEntry."Net Amount")
            { }
            column(LineDiscountAmount; TempGroupStoreTransSalesEntry."Discount Amount")
            { }
            column(isBenefitItem; TempGroupStoreTransSalesEntry."Item Number Scanned")
            { }
            column(BenefitsQty; TempGroupStoreTransSalesEntry."Standard Net Price")
            { }
            column(BenefitsAmount; TempGroupStoreTransSalesEntry."VAT Amount")
            { }
            column(ShowVariant; not RettailSetup."PLSPOS_Show Var for Report VIP")
            { }
            column(ShowLine; TempGroupStoreTransSalesEntry."Keyboard Item Entry")
            { }
            column(Discount_Amount; TempGroupStoreTransSalesEntry."Discount Amount")
            { }
            column(Variant_Code; TempGroupStoreTransSalesEntry."Variant Code")
            { }

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

    trigger OnPreReport()
    begin
        BuildDataset();
    end;

    local procedure BuildDataset()
    var
        DiscQuery: Query "PLSR_Q_DiscEntrySalesItem";
        BenefitQuery: Query "PLSR_Q_BenefitEntrySalesItem";
    begin
        TempTransSalesEntry.Reset();
        TempTransSalesEntry.DeleteAll();
        TempCopyTransSalesEntry.Reset();
        TempCopyTransSalesEntry.DeleteAll();
        TempGroupStoreTransSalesEntry.Reset();
        TempGroupStoreTransSalesEntry.DeleteAll();
        Clear(OldGroupBenefit);
        Clear(OldGroup);
        Clear(ShowLine);
        Clear(LineNo);
        Clear(SkipBenefitGroup);
        Clear(ItemDescCache);
        Clear(BarcodeCache);
        Clear(PromoDescCache);
        Clear(DiscEntryExistsCache);

        ComInfo.Get();
        RettailSetup.Get();

        IF Choose1Filter THEN BEGIN
            DateFilter := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
            PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        END ELSE
            IF Choose2Filter THEN BEGIN
                DateFilter := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
            END;

        IF (StoreFilter <> '') THEN
            ReportFilterText += 'Store No : ' + FORMAT(StoreFilter + ' ');

        ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFunction.AVTimeFormat(Time);

        if OfferFilter <> '' then
            if ReportFilterText <> '' then
                ReportFilterText += ',Promotion Filter No.: %1' + OfferFilter
            else
                ReportFilterText := 'Promotion Filter No.: %1' + OfferFilter;

        // ===== ตั้ง filter ให้ Query ก่อนเปิด (SQL ทำหน้าที่ join/filter ให้แทน AL loop) =====
        if StoreFilter <> '' then begin
            DiscQuery.SetFilter(Store_No, StoreFilter);
            BenefitQuery.SetFilter(Store_No, StoreFilter);
        end;
        if OfferFilter <> '' then begin
            DiscQuery.SetFilter(Offer_No, OfferFilter);
            BenefitQuery.SetFilter(Offer_No, OfferFilter);
        end;
        if DateFilter <> '' then begin
            DiscQuery.SetFilter(Header_Date, DateFilter);
            BenefitQuery.SetFilter(Header_Date, DateFilter);
        end;

        ProcessDiscEntryQuery(DiscQuery);
        ProcessBenefitEntryQuery(BenefitQuery);

        BuildGroupedTotals();
    end;

    // ===================================================================================
    // เดิม: dataitem "Trans. Discount Entry" วน GET ทีละแถวจาก "Trans. Sales Entry", Item, Barcodes
    // ใหม่: Query ทำ join ระดับ SQL ให้ (Item No., Item Description มาพร้อมแถวอยู่แล้ว)
    //       เหลือแค่ Barcode (pick-first) และ Promotion Description ที่ cache ด้วย Dictionary
    //       เพื่อให้ GET เกิดขึ้นแค่ "ครั้งแรกที่เจอค่านั้น" ไม่ใช่ทุกแถว
    // ===================================================================================
    local procedure ProcessDiscEntryQuery(var DiscQuery: Query "PLSR_Q_DiscEntrySalesItem")
    var
        CurrGroup2: Text[250];
        DiscKey: Text[250];
    begin
        DiscQuery.Open();
        while DiscQuery.Read() do begin
            LineNo += 1;
            Clear(OfferNo);
            Clear(DesPeriodicDiscount);
            OfferNo := DiscQuery.Offer_No;

            // Count Bill (logic เดิมทุกประการ)
            Clear(CountBill);
            CurrGroup2 := DiscQuery.Store_No + DiscQuery.POS_Terminal_No + Format(DiscQuery.Transaction_No) + OfferNo;
            IF (CurrGroup2 <> OldGroup) THEN
                if DiscQuery.Discount_Amount <> 0 then
                    CountBill := 1;
            OldGroup := CurrGroup2;

            // เก็บ key ไว้ใช้แทน TransDiscEntry.IsEmpty() ใน Benefit loop (เดิมต้อง query DB ทุกครั้ง)
            DiscKey := DiscQuery.Store_No + '|' + DiscQuery.POS_Terminal_No + '|' + Format(DiscQuery.Transaction_No) + '|' + OfferNo;
            if not DiscEntryExistsCache.ContainsKey(DiscKey) then
                DiscEntryExistsCache.Add(DiscKey, true);

            DesPeriodicDiscount := GetPromotionDescription(DiscQuery.Offer_Type, OfferNo);

            CLEAR(ItemPrice);
            CLEAR(LineQty);
            CLEAR(LineAmount);
            CLEAR(LineDiscAmount);
            ItemNo := DiscQuery.Item_No; // ได้จาก join แล้ว ไม่ต้อง GET "Trans. Sales Entry" เอง

            LineDiscAmount := DiscQuery.Discount_Amount;
            isBenefitItem := FALSE;
            ShowLine := true;

            CLEAR(BenefitsAmount);
            CLEAR(BenefitsQty);

            TempTransSalesEntry.Init();
            TempTransSalesEntry."Receipt No." := DiscQuery.Receipt_No;
            TempTransSalesEntry."Line No." := LineNo;
            TempTransSalesEntry."Store No." := DiscQuery.Store_No;
            TempTransSalesEntry."POS Terminal No." := DiscQuery.POS_Terminal_No;
            TempTransSalesEntry."Transaction No." := DiscQuery.Transaction_No;
            TempTransSalesEntry."Promotion No." := OfferNo;
            TempTransSalesEntry."Posting Exception Key" := DesPeriodicDiscount;
            TempTransSalesEntry."Barcode No." := GetBarcodeNo(ItemNo);
            TempTransSalesEntry."Item No." := ItemNo;
            TempTransSalesEntry."Item Number Scanned" := IsBenefitItem;
            TempTransSalesEntry."POS Line Description" := GetItemDescription(ItemNo, DiscQuery.Item_Description);
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
        DiscQuery.Close();
    end;

    // ===================================================================================
    // เดิม: dataitem "Trans. Disc. Benefit Entry" วน GET ทีละแถวจาก Item, Barcodes
    //       และเช็ค TransDiscEntry.IsEmpty() ทุกครั้งที่กลุ่มเปลี่ยน (query DB ซ้ำ)
    // ใหม่: Item Description มาจาก join ของ Query แล้ว, เช็คการมีอยู่ของ discount entry
    //       ด้วย Dictionary ที่สร้างไว้แล้วจาก ProcessDiscEntryQuery (ไม่ query DB ซ้ำอีก)
    //       SkipBenefitGroup ถูกกำหนดค่าเฉพาะตอน "กลุ่มเปลี่ยน" แล้วค้างค่าไว้ตลอดกลุ่มนั้น
    //       (เหมือนต้นฉบับที่ OldGroupBenefit ไม่ถูกอัปเดตเมื่อ CurrReport.Skip() ทำงาน
    //       ทำให้ทุกแถวในกลุ่มเดียวกันถูก skip เหมือนกันหมด ไม่ใช่แค่แถวแรกของกลุ่ม)
    // ===================================================================================
    local procedure ProcessBenefitEntryQuery(var BenefitQuery: Query "PLSR_Q_BenefitEntrySalesItem")
    var
        CurrGroupBenefit2: Text[250];
        DiscKey: Text[250];
    begin
        BenefitQuery.Open();
        while BenefitQuery.Read() do begin
            LineNo += 1;
            Clear(OfferNo);
            OfferNo := BenefitQuery.Offer_No;

            Clear(CountBill);
            CurrGroupBenefit2 := BenefitQuery.Store_No + BenefitQuery.POS_Terminal_No + Format(BenefitQuery.Transaction_No) + OfferNo;
            IF (CurrGroupBenefit2 <> OldGroupBenefit) THEN begin
                DiscKey := BenefitQuery.Store_No + '|' + BenefitQuery.POS_Terminal_No + '|' + Format(BenefitQuery.Transaction_No) + '|' + OfferNo;
                if DiscEntryExistsCache.ContainsKey(DiscKey) then
                    SkipBenefitGroup := true
                else begin
                    SkipBenefitGroup := false;
                    CountBill := 1;
                end;
                OldGroupBenefit := CurrGroupBenefit2;
            end;

            if not SkipBenefitGroup then begin
                DesPeriodicDiscount := GetPromotionDescription("LSC Trans. Disc. Ent Offer Typ"::"Total Discount", OfferNo);

                ItemNo := BenefitQuery.Item_No; // ได้จาก join แล้ว ไม่ต้อง GET Item เอง

                CLEAR(ItemPrice);
                CLEAR(LineQty);
                CLEAR(LineAmount);
                CLEAR(LineDiscAmount);
                ItemPrice := BenefitQuery.Benefit_Value;
                LineQty := BenefitQuery.Benefit_Quantity;
                LineAmount := BenefitQuery.Benefit_Quantity * BenefitQuery.Benefit_Value;
                LineDiscAmount := 0;

                isBenefitItem := TRUE;

                CLEAR(BenefitsAmount);
                BenefitsAmount := BenefitQuery.Benefit_Quantity * BenefitQuery.Benefit_Value;

                CLEAR(BenefitsQty);
                BenefitsQty := BenefitQuery.Benefit_Quantity;

                Clear(ShowLine);
                if BenefitQuery.Benefit_Type = BenefitQuery.Benefit_Type::Item then
                    ShowLine := true;

                TempTransSalesEntry.Init();
                TempTransSalesEntry."Receipt No." := BenefitQuery.Receipt_No;
                TempTransSalesEntry."Line No." := LineNo;
                TempTransSalesEntry."Store No." := BenefitQuery.Store_No;
                TempTransSalesEntry."POS Terminal No." := BenefitQuery.POS_Terminal_No;
                TempTransSalesEntry."Transaction No." := BenefitQuery.Transaction_No;
                TempTransSalesEntry."Promotion No." := OfferNo;
                TempTransSalesEntry."Posting Exception Key" := DesPeriodicDiscount;
                TempTransSalesEntry."Barcode No." := GetBarcodeNo(ItemNo);
                TempTransSalesEntry."Item No." := ItemNo;
                TempTransSalesEntry."Item Number Scanned" := IsBenefitItem;
                TempTransSalesEntry."POS Line Description" := GetItemDescription(ItemNo, BenefitQuery.Item_Description);
                TempTransSalesEntry."Deal Header Line No." := CountBill;
                TempTransSalesEntry."Net Amount" := LineAmount;
                TempTransSalesEntry."Discount Amount" := LineDiscAmount;
                TempTransSalesEntry."VAT Amount" := BenefitsAmount;
                TempTransSalesEntry."Keyboard Item Entry" := ShowLine;
                TempTransSalesEntry."Standard Net Price" := BenefitsQty;
                TempTransSalesEntry.Price := ItemPrice;
                TempTransSalesEntry.Quantity := LineQty;
                if TempTransSalesEntry.Insert() then;

                TempCopyTransSalesEntry.Init();
                TempCopyTransSalesEntry.Copy(TempTransSalesEntry);
                if TempCopyTransSalesEntry.Insert() then;
            end;
        end;
        BenefitQuery.Close();
    end;

    // Cache: คำอธิบายโปรโมชั่น/คูปอง โหลดจาก DB แค่ครั้งแรกที่เจอ OfferNo นั้น ๆ (เดิม GET ทุกแถว)
    local procedure GetPromotionDescription(OfferType: Enum "LSC Trans. Disc. Ent Offer Typ"; OffNo: Code[30]): Text[100]
    var
        CacheKey: Text[150];
        Desc: Text[100];
    begin
        CacheKey := Format(OfferType) + '|' + OffNo;
        if PromoDescCache.ContainsKey(CacheKey) then
            exit(PromoDescCache.Get(CacheKey));

        Clear(Desc);
        if OfferType = OfferType::"Total Discount" then begin
            CLEAR(PeriodicDiscTB);
            PeriodicDiscTB.SetLoadFields(Description);
            IF PeriodicDiscTB.GET(OffNo) THEN
                Desc := PeriodicDiscTB.Description;
        end else begin
            CLEAR(CouponHeader);
            CouponHeader.SetLoadFields(Description);
            IF CouponHeader.GET(OffNo) THEN
                Desc := CouponHeader.Description;
        end;
        PromoDescCache.Add(CacheKey, Desc);
        exit(Desc);
    end;

    // Cache: Barcode No. แรกของ Item โหลดจาก DB แค่ครั้งแรกที่เจอ Item No. นั้น ๆ (เดิม FINDFIRST ทุกแถว และเดิมใช้ key ผิด ทำให้สแกนทั้งตาราง)
    local procedure GetBarcodeNo(ItNo: Code[20]): Code[20]
    var
        BcNo: Code[20];
    begin
        if BarcodeCache.ContainsKey(ItNo) then
            exit(BarcodeCache.Get(ItNo));

        Clear(BcNo);
        CLEAR(BarcodesTB);
        BarcodesTB.SetCurrentKey("Item No."); // คีย์ตรงกับ filter จริง (เดิมตั้งคีย์ผิดเป็น "Barcode No." ทำให้สแกนทั้งตาราง)
        BarcodesTB.SETRANGE("Item No.", ItNo);
        BarcodesTB.SetLoadFields("Barcode No.");
        IF BarcodesTB.FINDFIRST() THEN
            BcNo := BarcodesTB."Barcode No.";

        BarcodeCache.Add(ItNo, BcNo);
        exit(BcNo);
    end;

    // Cache: คำอธิบายสินค้า ใช้ค่าจาก Query join ถ้ามี (ไม่ต้อง GET ซ้ำเลย); cache ไว้เผื่อ Query ไม่เจอ (left outer join ไม่ match)
    local procedure GetItemDescription(ItNo: Code[20]; QueryItemDescription: Text[100]): Text[100]
    var
        Desc: Text[100];
    begin
        if QueryItemDescription <> '' then
            exit(QueryItemDescription);

        if ItemDescCache.ContainsKey(ItNo) then
            exit(ItemDescCache.Get(ItNo));

        Clear(Desc);
        CLEAR(ItemTB);
        ItemTB.SetLoadFields(Description);
        IF ItemTB.GET(ItNo) THEN
            Desc := ItemTB.Description;

        ItemDescCache.Add(ItNo, Desc);
        exit(Desc);
    end;

    // ===== Logic การ group/sub-total เหมือนต้นฉบับ (V1.1) ทุกประการ ไม่เปลี่ยนแปลง =====
    local procedure BuildGroupedTotals()
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

                // เดิม insert แถวสรุปยอดระดับ Store+Offer ลง TempGroupOfferTransSalesEntry (คนละตารางกับที่ report พิมพ์)
                // ซึ่ง report dataitem พิมพ์เฉพาะ TempGroupStoreTransSalesEntry เท่านั้น ทำให้แถวสรุปนี้หายไปจากรายงาน
                // แก้ให้ insert ลง TempGroupStoreTransSalesEntry ตัวเดียวกับต้นฉบับ (พฤติกรรมเดิมทุกประการ
                // รวมถึงกรณี key ชนกับแถว item-level ด้านบนแล้วถูก skip เงียบ ๆ เหมือนต้นฉบับ)
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

    var
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        CouponHeader: Record "LSC Coupon Header";
        PeriodicDiscTB: Record "LSC Periodic Discount";
        BarcodesTB: Record "LSC Barcodes";
        ItemTB: Record Item;
        RettailSetup: Record "LSC Retail Setup";
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
        OldGroup: Text[250];
        DesPeriodicDiscount: Text[100];
        FDateFilter: Date;
        FromDateFilter: Date;
        TodateFilter: Date;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        StoreFilter: Code[20];
        DateFilter: Text[100];
        OldGroupBenefit: Text[250];
        ShowLine: Boolean;
        SkipBenefitGroup: Boolean;
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
        ItemDescCache: Dictionary of [Code[20], Text[100]];
        BarcodeCache: Dictionary of [Code[20], Code[20]];
        PromoDescCache: Dictionary of [Text[150], Text[100]];
        DiscEntryExistsCache: Dictionary of [Text[250], Boolean];
    // C-AVPWDLSVIP 01/07/2026 > Improve Performance of VIP Report(76088) - น้องปอ
}