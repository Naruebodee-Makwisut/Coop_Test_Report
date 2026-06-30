report 50108 "PLSR_Tot_Offer Sales Item Pro"
{
    Caption = 'Total Offer Sales Item By Promotion';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep76088_TotalOfferSalesItemByPromotion.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Transaction Header"; "LSC Transaction Header")
        {
            DataItemTableView = sorting("Store No.", "POS Terminal No.", "Transaction No.")
                                where("Transaction Type" = CONST(Sales), "Entry Status" = FILTER(<> Voided));
            //RequestFilterFields = Date, "Store No.";
            PrintOnlyIfDetail = true;
            // column(Name_ComInfo; ComInfo.Name)
            // { }
            // column(ShowDate; ShowDate)
            // { }
            // column(ShowTime; ShowTime)
            // { }
            // column(PeriodDate; PeriodDate)
            // { }
            // column(ReportFilterText; ReportFilterText)
            // { }
            // column(StoreNo_TransactionHeader; "Transaction Header"."Store No.")
            // { }
            // column(Receipt_No_; "Receipt No.")
            // { }
            // column(OfferNo; OfferNo)
            // { }
            // column(CountBill; CountBill)
            // { }
            // column(Description_PeriodicDiscount; PeriodicDiscTB.Description)
            // { }
            // column(ItemNo_TransSalesEntry; ItemNo)
            // { }
            // column(BarcodeNo_TransSaleEntry; BarcodesTB."Barcode No.")
            // { }
            // column(ItemDescription_TransSalesEntry; ItemTB.Description)
            // { }
            // column(Price_TransSalesEntry; ItemPrice)
            // { }
            // column(LineQty; LineQty)
            // { }
            // column(LineAmount; LineAmount)
            // { }
            // column(LineDiscountAmount; LineDiscAmount)
            // { }
            // column(isBenefitItem; isBenefitItem)
            // { }
            // column(BenefitsQty; BenefitsQty)
            // { }
            // column(BenefitsAmount; BenefitsAmount)
            // { }
            // column(ShowVariant; not RettailSetup."PLSPOS_Show Var for Report VIP")
            // { }
            // column(ShowLine; ShowLine)
            // { }
            dataitem("Trans. Discount Entry"; "LSC Trans. Discount Entry")
            {
                DataItemTableView = SORTING("Store No.", "POS Terminal No.", "Transaction No.", "Line No.", "Offer Type", "Offer No.")
                                    WHERE("Offer Type" = FILTER("Total Discount" | Coupon), "Discount Amount" = filter(<> 0));
                DataItemLink = "Transaction No." = FIELD("Transaction No."), "Store No." = FIELD("Store No."), "POS Terminal No." = FIELD("POS Terminal No.");

                // column(TranscationNo_TransDiscountEntry; "Trans. Discount Entry"."Transaction No.")
                // { }
                // column(Discount_Amount; "Discount Amount")
                // { }

                trigger OnPreDataItem()
                begin
                    if OfferFilter <> '' then
                        SetFilter("Offer No.", OfferFilter);
                end;

                trigger OnAfterGetRecord()
                begin
                    LineNo += 1;
                    Clear(OfferNo);
                    Clear(DesPeriodicDiscount);
                    OfferNo := "Trans. Discount Entry"."Offer No.";

                    //Count Bill
                    Clear(CountBill);
                    CurrGroup := "Transaction Header"."Store No." + "Transaction Header"."POS Terminal No." + FORMAT("Transaction Header"."Transaction No.") + OfferNo;
                    IF (CurrGroup <> OldGroup) THEN
                        if "Trans. Discount Entry"."Discount Amount" <> 0 then
                            CountBill := 1;
                    OldGroup := CurrGroup;
                    //Count Bill - end

                    IF "Trans. Discount Entry"."Offer Type" = "Trans. Discount Entry"."Offer Type"::"Total Discount" THEN BEGIN
                        CLEAR(PeriodicDiscTB);
                        IF PeriodicDiscTB.GET(OfferNo) THEN
                            DesPeriodicDiscount := PeriodicDiscTB.Description;
                    END ELSE BEGIN
                        CLEAR(CouponHeader);
                        IF CouponHeader.GET(OfferNo) THEN
                            DesPeriodicDiscount := CouponHeader.Description;
                    END;

                    CLEAR(ItemPrice);
                    CLEAR(LineQty);
                    CLEAR(LineAmount);
                    CLEAR(LineDiscAmount);
                    CLEAR(TransSalesEntry);
                    IF TransSalesEntry.GET("Trans. Discount Entry"."Store No.", "Trans. Discount Entry"."POS Terminal No.", "Trans. Discount Entry"."Transaction No.", "Trans. Discount Entry"."Line No.") THEN BEGIN
                        CLEAR(BarcodesTB);
                        BarcodesTB.SETCURRENTKEY("Barcode No.");
                        BarcodesTB.SETRANGE("Item No.", TransSalesEntry."Item No.");
                        BarcodesTB.SetLoadFields("Barcode No.");
                        IF BarcodesTB.FINDFIRST() THEN;

                        CLEAR(ItemNo);
                        CLEAR(ItemTB);
                        IF ItemTB.GET(TransSalesEntry."Item No.") THEN
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
                    TempTransSalesEntry."Posting Exception Key" := PeriodicDiscTB.Description;
                    TempTransSalesEntry."Barcode No." := BarcodesTB."Barcode No.";
                    TempTransSalesEntry."Item No." := ItemNo;
                    TempTransSalesEntry."Item Number Scanned" := IsBenefitItem;
                    TempTransSalesEntry."POS Line Description" := ItemTB.Description;
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
                // column(Transaction_No_; "Transaction No.")
                // { }
                // column(Variant_Code; "Variant Code")
                // { }

                trigger OnPreDataItem()
                begin
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

                    //Count Bill
                    //if CountBill = 0 then begin
                    Clear(CountBill);
                    CurrGroupBenefit := "Transaction Header"."Store No." + "Transaction Header"."POS Terminal No." + FORMAT("Transaction Header"."Transaction No.") + OfferNo;
                    IF (CurrGroupBenefit <> OldGroupBenefit) THEN begin
                        Clear(TransDiscEntry);
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
                    //end else
                    //    Clear(CountBill);
                    //Count Bill - end

                    CLEAR(PeriodicDiscTB);
                    IF PeriodicDiscTB.GET(OfferNo) THEN;

                    CLEAR(BarcodesTB);
                    BarcodesTB.SETCURRENTKEY("Barcode No.");
                    BarcodesTB.SETRANGE("Item No.", "Trans. Disc. Benefit Entry"."No.");
                    BarcodesTB.SetLoadFields("Barcode No.");
                    IF BarcodesTB.FINDFIRST() THEN;

                    CLEAR(ItemNo);
                    CLEAR(ItemTB);
                    IF ItemTB.GET("Trans. Disc. Benefit Entry"."No.") THEN
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
                    TempTransSalesEntry."Item Number Scanned" := IsBenefitItem;
                    TempTransSalesEntry."POS Line Description" := ItemTB.Description;
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
            }

            trigger OnPreDataItem()
            begin
                TempTransSalesEntry.Reset();
                TempTransSalesEntry.DeleteAll();
                TempCopyTransSalesEntry.Reset();
                TempCopyTransSalesEntry.DeleteAll();

                Clear(OldGroupBenefit);
                Clear(OldGroup);
                Clear(ShowLine);

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
                // ===== FIX (V1.1) =====
                // เดิม: ใช้ TempGroupStoreTransSalesEntry ตัวเดียวเก็บทั้ง "summary ระดับ Item"
                // และ "summary ระดับ Store/Promotion" ปนกัน ไม่มีอะไรแยกสองระดับนี้ออกจากกัน
                // ผลคือเมื่อ ItemCurr<>ItemNew และ StoreOfferCurr<>StoreOfferNew เป็นจริงพร้อมกัน
                // (กรณี item เป็นรายการสุดท้ายของ promotion นั้นพอดี ซึ่งเกิดขึ้นบ่อยมาก)
                // จะมีการ Insert() แถวที่มีความหมายต่างกัน (sub-total คนละระดับ) ลงตารางเดียวกัน
                // -> ทำให้จำนวน record ที่ใช้ render บวมขึ้นเกือบเท่าตัว (รายงานช้า, จำนวนหน้าเพิ่มผิดปกติ)
                // -> และทำให้ RDLC matrix (ที่ pivot คอลัมน์ตาม Promotion No.) นับ/แม็พคอลัมน์ผิดตำแหน่ง
                //    เพราะมี record สองระดับปนกันในชุดข้อมูลเดียวที่ใช้ render
                //
                // แก้โดย: แยกเป็น 2 temporary table ไปเลย
                //   - TempGroupStoreTransSalesEntry = แถวระดับ Item-Group (ใช้ render รายละเอียดสินค้าจริงใน matrix เหมือนเดิม)
                //   - TempGroupOfferTransSalesEntry = แถวระดับ Store/Promotion-Group (sub-total ภายใน ไม่ใช้ render)
                // dataitem(Integer) ด้านล่างยังคงอ้างอิง TempGroupStoreTransSalesEntry เหมือนเดิมทุกประการ
                // (ไม่กระทบ RDLC layout เดิมเลย) แต่ตอนนี้จะมีแค่แถว Item-Group เท่านั้น ไม่ปนกับ sub-total อีกต่อไป

                TempGroupStoreTransSalesEntry.Reset();
                TempGroupStoreTransSalesEntry.DeleteAll();
                TempGroupOfferTransSalesEntry.Reset();
                TempGroupOfferTransSalesEntry.DeleteAll();
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

                        // ----- ระดับ Item-Group: insert ลง TempGroupStoreTransSalesEntry (ตัวเดิมที่ RDLC ใช้ render) -----
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

                        // ----- ระดับ Store/Promotion-Group: insert ลง TempGroupOfferTransSalesEntry (ตารางแยกใหม่) -----
                        // FIX (V1.1): เดิม insert ลงตารางเดียวกับ Item-Group ด้านบน ทำให้แถว sub-total
                        // ปนเข้าไปในชุดข้อมูลที่ใช้ render รายละเอียด -> คอลัมน์โปรโมชั่นเลื่อน/แม็พผิดตำแหน่ง
                        // และจำนวนหน้าเพิ่มผิดปกติ (รายงานช้า)
                        if StoreOfferCurr <> StoreOfferNew then begin
                            TempGroupOfferTransSalesEntry.Init();
                            TempGroupOfferTransSalesEntry := TempTransSalesEntry;
                            TempGroupOfferTransSalesEntry."Deal Header Line No." := NewCountBill;
                            TempGroupOfferTransSalesEntry."Standard Net Price" := NewBenefitsQty;
                            TempGroupOfferTransSalesEntry."Net Amount" := NewLineAmount;
                            TempGroupOfferTransSalesEntry."Discount Amount" := NewLineDiscAmount;
                            TempGroupOfferTransSalesEntry."VAT Amount" := NewBenefitAmt;
                            if TempGroupOfferTransSalesEntry.Insert() then;
                        end;
                    until TempTransSalesEntry.Next() = 0;
            end;
        }
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
            // FDateFilter := Today;
            // Choose1Filter := false;
            // Choose2Filter := true;
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
        TempGroupOfferTransSalesEntry: Record "LSC Trans. Sales Entry" temporary; // FIX (V1.1): ตารางแยกสำหรับแถว Store/Promotion-level sub-total ไม่ให้ปนกับแถว Item-Group
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