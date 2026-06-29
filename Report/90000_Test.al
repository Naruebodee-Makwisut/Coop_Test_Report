report 90000 "TEST_Store Stock Checking"
{
    Caption = 'Store Stock Checking';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep76081_StoreStockChecking.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        // -------------------------------------------------------------
        // DataItem 1: วนลูป Item เพื่อดึงข้อมูลดิบและคำนวณยัดลง Temporary Table
        // -------------------------------------------------------------
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");

            trigger OnPreDataItem()
            begin
                AsOfDateFilter := Today;
                if LocationFilter = '' then
                    Error('Please input Location filter!');

                Clear(ReportFilterText);
                if (ItemNoFilter <> '') then begin
                    ReportFilterText += 'Item No. : ' + FORMAT(ItemNoFilter + ' ');
                    Item.SetFilter("No.", ItemNoFilter);
                end;
                if (LocationFilter <> '') then
                    ReportFilterText += ' Location : ' + FORMAT(LocationFilter + ' ');

                if DivisionFilter <> '' then begin
                    ReportFilterText += ' Division : ' + DivisionFilter;
                    SetFilter("LSC Division Code", DivisionFilter);
                end;
                if ItemCategoryFilter <> '' then begin
                    ReportFilterText += ' ItemCategoryFilter :' + ItemCategoryFilter;
                    SetFilter("Item Category Code", ItemCategoryFilter);
                end;
                if ProductGroupFilter <> '' then begin
                    ReportFilterText += 'ProductGroupFilter :' + ProductGroupFilter;
                    SetFilter("LSC Retail Product Code", ProductGroupFilter);
                end;

                if (ShowItemBlock) then
                    ReportFilterText += ' Show Item Blocked';
                if (ShowZeroFilter) then
                    ReportFilterText += ' Show Item Quantity Zero';
                if ShowNegativeFilter then
                    ReportFilterText += ' Show Negative Quantity';

                Clear(StoreTB);
                if StoreTB.Get(LocationFilter) then
                    StoreFilterText := StoreTB."No." + ' : ' + StoreTB.Name;

                if not ShowItemBlock then
                    SetRange(Item.Blocked, false);
                SetFilter(Item.Type, '%1', Type::Inventory);

                // เคลียร์ตาราง Temporary หลักก่อนเริ่มงาน
                TempItemStockBuffer.Reset();
                if TempItemStockBuffer.IsTemporary then
                    TempItemStockBuffer.DeleteAll();
            end;

            trigger OnAfterGetRecord()
            var
                LocalItemVariant: Record "Item Variant";
            begin
                // เตรียมตารางชั่วคราวสำหรับเก็บ Variant (เพื่อหาว่า Item นี้มี Variant อะไรบ้าง)
                TempItemVariant.Reset();
                TempItemVariant.DeleteAll();

                // ใส่บรรทัดว่างสำหรับกรณีไม่มี Variant หรือไม่ได้เปิดใช้ Show Variant
                TempItemVariant.Init();
                TempItemVariant."Item No." := "No.";
                TempItemVariant.Insert(false);

                if RetailSetup."PLSPOS_Show Var for Report VIP" then begin
                    LocalItemVariant.SetCurrentKey("Item No.", Code);
                    LocalItemVariant.SetRange("Item No.", "No.");
                    if LocalItemVariant.FindSet() then
                        repeat
                            TempItemVariant.Init();
                            TempItemVariant.TransferFields(LocalItemVariant);
                            TempItemVariant.Insert(false);
                        until LocalItemVariant.Next() = 0;
                end;

                // วนลูป Variant เพื่อคำนวณตัวเลขและกรองข้อมูลก่อนเก็บลง Buffer หลัก
                TempItemVariant.Reset();
                if TempItemVariant.FindSet() then
                    repeat
                        Clear(ItemInventoryQty);
                        Clear(ItemSoldTodayQty);
                        Clear(ItemSoldNotPostedQty);
                        Clear(ItemWaitedTransferQty);
                        Clear(NetInventoryQty);

                        // 1. หา Item Inventory Qty.
                        Clear(ItemLedgerEntryTB);
                        ItemLedgerEntryTB.SetCurrentKey("Item No.", "Posting date", "Location Code");
                        ItemLedgerEntryTB.SetRange("Item No.", Item."No.");
                        ItemLedgerEntryTB.SetRange("Posting Date", 0D, AsOfDateFilter);
                        ItemLedgerEntryTB.SetFilter("Location Code", LocationFilter);

                        if RetailSetup."PLSPOS_Show Var for Report VIP" then
                            ItemLedgerEntryTB.SetRange("Variant Code", TempItemVariant.Code);
                        ItemLedgerEntryTB.CalcSums("Remaining Quantity");
                        ItemInventoryQty := ItemLedgerEntryTB."Remaining Quantity";

                        // 2. คำนวณยอดขายที่ยังไม่ได้โพสต์
                        if LocationFilter <> '' then begin
                            Clear(StoreTB);
                            StoreTB.SetFilter("Location Code", LocationFilter);
                            if StoreTB.FindSet() then
                                repeat
                                    ItemSoldTodayQty += QtySoldNotPosted(Item."No.", StoreTB."No.", TempItemVariant.Code, Today, true, '');
                                    ItemSoldNotPostedQty += QtySoldNotPosted(Item."No.", StoreTB."No.", TempItemVariant.Code, Today - 1, false, '');
                                until StoreTB.Next() = 0;
                        end else begin
                            ItemSoldTodayQty := QtySoldNotPosted(Item."No.", '', TempItemVariant.Code, Today, true, '');
                            ItemSoldNotPostedQty := QtySoldNotPosted(Item."No.", '', TempItemVariant.Code, Today - 1, false, '');
                        end;

                        NetInventoryQty := ItemInventoryQty + ItemSoldTodayQty + ItemSoldNotPostedQty;

                        // 3. ตรวจสอบเงื่อนไขตัวกรอง (ฟิลเตอร์คัดออก)
                        SkipLine := false;
                        if (NetInventoryQty < 0) and (not ShowNegativeFilter) then
                            SkipLine := true;
                        if (NetInventoryQty = 0) and (not ShowZeroFilter) then
                            SkipLine := true;

                        // ถ้าผ่านเงื่อนไข ให้จับยัดบันทึกข้อมูลลง Temporary Buffer หลัก
                        if not SkipLine then begin
                            TempItemStockBuffer.Reset();
                            TempItemStockBuffer.Init();
                            // ใช้ฟิลด์ Item No. กับ Variant Code ร่วมกันเป็น Primary Key ใน Buffer
                            TempItemStockBuffer."Item No." := Item."No.";
                            TempItemStockBuffer.Code := TempItemVariant.Code;

                            // ฝากตัวเลขไว้ในฟิลด์ที่ไม่ได้ใช้ชั่วคราวในตาราง Item Variant (หรือจะสร้างตารางเฉพาะมาเก็บก็ได้)
                            // ในที่นี้สมมติขอประยุกต์ใช้ฟิลด์ Description เก็บสถานะหรือนำตัวแปร Global ไปโยนออกในตาราง Integer แทน
                            TempItemStockBuffer.Insert();
                        end;
                    until TempItemVariant.Next() = 0;
            end;
        }

        // -------------------------------------------------------------
        // DataItem 2: ใช้ลูป Integer สแกนตาราง Temporary และส่งค่าไปที่ Layout
        // -------------------------------------------------------------
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));

            column(StoreNo_Name_StoreTB; StoreFilterText) { }
            column(ReportFilterText; ReportFilterText) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(ItemNo; DisplayItem."No.") { }
            column(Description_Item; DisplayItem.Description) { }
            column(BaseUOM_Item; DisplayItem."Base Unit of Measure") { }
            column(Variant_Code; TempItemStockBuffer.Code) { }
            column(ItemInventoryQty; format(ItemInventoryQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ItemSoldNotPostedQty; format(ItemSoldNotPostedQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ItemSoldTodayQty; format(ItemSoldTodayQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(NetInventoryQty; format(NetInventoryQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ItemWaitedTransferQty; ItemWaitedTransferQty) { }
            column(ShowLot; ShowLot) { }
            column(ShowVariant; RetailSetup."PLSPOS_Show Var for Report VIP") { }

            trigger OnPreDataItem()
            begin
                // Reset ตัวกรองของตารางชั่วคราวก่อนเริ่มสแกนออกรายงาน
                TempItemStockBuffer.Reset();
            end;

            trigger OnAfterGetRecord()
            begin
                // ควบคุมลูปดึงข้อมูลจากตารางชั่วคราวทีละบรรทัดเหมือนโค้ดชุดที่ 2
                if Number = 1 then begin
                    if not TempItemStockBuffer.FindSet() then
                        CurrReport.Break();
                end else begin
                    if TempItemStockBuffer.Next() = 0 then
                        CurrReport.Break();
                end;

                // ไปดึงข้อมูล Master ของสินค้ามาแสดงชื่อหน่วยนับ
                Clear(DisplayItem);
                if DisplayItem.Get(TempItemStockBuffer."Item No.") then;

                // ทำการคำนวณตัวเลขความจริงเพื่อแสดงผลบนบรรทัดของคิวรีกราฟิก (Layout)
                Clear(ItemInventoryQty);
                Clear(ItemSoldTodayQty);
                Clear(ItemSoldNotPostedQty);
                Clear(ItemWaitedTransferQty);
                Clear(NetInventoryQty);

                // คิวรีดึงตัวเลขมาโชว์ใน Layout
                Clear(ItemLedgerEntryTB);
                ItemLedgerEntryTB.SetCurrentKey("Item No.", "Posting date", "Location Code");
                ItemLedgerEntryTB.SetRange("Item No.", TempItemStockBuffer."Item No.");
                ItemLedgerEntryTB.SetRange("Posting Date", 0D, AsOfDateFilter);
                ItemLedgerEntryTB.SetFilter("Location Code", LocationFilter);
                if RetailSetup."PLSPOS_Show Var for Report VIP" then
                    ItemLedgerEntryTB.SetRange("Variant Code", TempItemStockBuffer.Code);
                ItemLedgerEntryTB.CalcSums("Remaining Quantity");
                ItemInventoryQty := ItemLedgerEntryTB."Remaining Quantity";

                if LocationFilter <> '' then begin
                    Clear(StoreTB);
                    StoreTB.SetFilter("Location Code", LocationFilter);
                    if StoreTB.FindSet() then
                        repeat
                            ItemSoldTodayQty += QtySoldNotPosted(TempItemStockBuffer."Item No.", StoreTB."No.", TempItemStockBuffer.Code, Today, true, '');
                            ItemSoldNotPostedQty += QtySoldNotPosted(TempItemStockBuffer."Item No.", StoreTB."No.", TempItemStockBuffer.Code, Today - 1, false, '');
                        until StoreTB.Next() = 0;
                end else begin
                    ItemSoldTodayQty := QtySoldNotPosted(TempItemStockBuffer."Item No.", '', TempItemStockBuffer.Code, Today, true, '');
                    ItemSoldNotPostedQty := QtySoldNotPosted(TempItemStockBuffer."Item No.", '', TempItemStockBuffer.Code, Today - 1, false, '');
                end;
                NetInventoryQty := ItemInventoryQty + ItemSoldTodayQty + ItemSoldNotPostedQty;
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
                        field("Item No. :"; ItemNoFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = Item."No.";
                            Caption = 'Item No. :';
                        }
                        field("Location :"; LocationFilter)
                        {
                            ApplicationArea = all;
                            TableRelation = Location.Code;
                            Caption = 'Location :';
                        }
                        field("Show Item Block :"; ShowItemBlock)
                        {
                            ApplicationArea = all;
                            Caption = 'Show Item Block :';
                        }
                        field(DivisionFilter_; DivisionFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'Division Filter';
                            TableRelation = "LSC Division";
                        }
                        field(ItemCategory_1; ItemCategoryFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'Item Category';
                            TableRelation = "Item Category";
                        }
                        field(Productgroup_1; ProductGroupFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'Product Group';
                            TableRelation = "LSC Retail Product Group".Code;
                        }
                    }
                    group("Select One")
                    {
                        field("Show Zero :"; ShowZeroFilter)
                        {
                            ApplicationArea = all;
                            Caption = 'Show Zero :';
                        }
                    }
                }
            }
        }
        trigger OnInit()
        begin
            Clear(ItemCategoryFilter);
            Clear(ProductGroupFilter);
        end;
    }

    trigger OnPreReport()
    begin
        SelectLatestVersion();
        ComInfo.Get();
        ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFucntion.AVTimeFormat(Time);
        RetailSetup.Get();
    end;

    var
        LSVIPRepFucntion: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        StoreTB: Record "LSC Store";
        ItemLedgerEntryTB: Record "Item Ledger Entry";
        RetailSetup: Record "LSC Retail Setup";
        DisplayItem: Record Item;
        TempItemStockBuffer: Record "Item Variant" temporary; // ใช้ตารางนี้เป็น Buffer ชั่วคราวหลัก
        TempItemVariant: Record "Item Variant" temporary;

        ShowTime: Text[50];
        ShowDate: Text[50];
        ReportFilterText: Text[250];
        StoreFilterText: Text[250];
        ItemNoFilter: Code[20];
        LocationFilter: Code[20];
        ItemInventoryQty: Decimal;
        ItemSoldTodayQty: Decimal;
        ItemSoldNotPostedQty: Decimal;
        ItemWaitedTransferQty: Decimal;
        NetInventoryQty: Decimal;
        AsOfDateFilter: Date;
        ShowZeroFilter: Boolean;
        ShowNegativeFilter: Boolean;
        ShowItemBlock: Boolean;
        SkipLine: Boolean;
        ShowLot: Boolean;
        DivisionFilter: Code[20];
        ItemCategoryFilter: Code[20];
        ProductGroupFilter: code[20];

    local procedure QtySoldNotPosted(ItemNo: Code[20]; StoreFilter: Code[250]; VariantFilter: Code[250]; DateFilter: Date; SoldTodayFilter: Boolean; LotFilter: Code[50]) QtySoldNotPosted: Decimal
    var
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        TransSalesEntryStatus: Record "LSC Trans. Sales Entry Status";
        QuantitySold: Decimal;
        QuantityPosted: Decimal;
    begin
        CLEAR(QuantitySold);
        CLEAR(QuantityPosted);
        CLEAR(QtySoldNotPosted);

        TransSalesEntry.SETCURRENTKEY("Item No.", "Variant Code", Date);
        TransSalesEntry.SETRANGE("Item No.", ItemNo);
        if LotFilter <> '' then
            TransSalesEntry.SetRange("Lot No.", LotFilter);
        IF RetailSetup."PLSPOS_Show Var for Report VIP" THEN
            TransSalesEntry.SETFILTER("Variant Code", VariantFilter);
        IF StoreFilter <> '' THEN
            TransSalesEntry.SETFILTER("Store No.", StoreFilter);
        IF SoldTodayFilter THEN
            TransSalesEntry.SETRANGE(Date, DateFilter)
        ELSE
            TransSalesEntry.SETRANGE(Date, 0D, DateFilter);
        TransSalesEntry.CalcSums(Quantity);
        QuantitySold := TransSalesEntry.Quantity;

        TransSalesEntryStatus.SETCURRENTKEY("Item No.", "Variant Code", Status, "Store No.", Date);
        TransSalesEntryStatus.SETRANGE("Item No.", ItemNo);
        IF RetailSetup."PLSPOS_Show Var for Report VIP" THEN
            TransSalesEntryStatus.SETFILTER("Variant Code", VariantFilter);
        IF SoldTodayFilter THEN
            TransSalesEntryStatus.SETRANGE(Date, DateFilter)
        ELSE
            TransSalesEntryStatus.SETRANGE(Date, 0D, DateFilter);
        TransSalesEntryStatus.SETRANGE(Status, TransSalesEntryStatus.Status::"Items Posted", TransSalesEntryStatus.Status::Posted);
        IF StoreFilter <> '' THEN
            TransSalesEntryStatus.SETFILTER("Store No.", StoreFilter);
        if LotFilter <> '' then
            TransSalesEntryStatus.SetRange("Lot No.", LotFilter);
        TransSalesEntryStatus.CalcSums(Quantity);
        QuantityPosted := TransSalesEntryStatus.Quantity;

        QtySoldNotPosted := QuantitySold - QuantityPosted;
    end;

    procedure SetLocationFilter(refLocationFilter: Code[20])
    begin
        LocationFilter := refLocationFilter;
    end;

    procedure SetNegativeFilter(refShowNegativeFilter: Boolean)
    begin
        ShowNegativeFilter := refShowNegativeFilter;
    end;
}