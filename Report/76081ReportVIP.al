report 50105 "Store Stock Checking"
{
    Caption = 'Store Stock Checking';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50105_StoreStockChecking.rdl';
    PreviewMode = PrintLayout;
    // AVPWDLSVIP 26/06/2025 > Improve Performance of VIP Report(76081) น้องอิง
    dataset
    {
        dataitem(Integer; Integer)
        {
<<<<<<< HEAD
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
=======
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
>>>>>>> b8f4287c17910c5af2d2f36ad697bf69b2856e86

            column(StoreNo_Name_StoreTB; StoreFilterText) { }
            column(ReportFilterText; ReportFilterText) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
<<<<<<< HEAD

            column(ItemNo; TempStockBuffer."Item No.") { }
            column(Description_Item; TempStockBuffer.Description) { }
            column(BaseUOM_Item; TempStockBuffer."Base Unit of Measure") { }
            column(Variant_Code; TempStockBuffer."Variant Code") { }

            column(ItemInventoryQty; format(TempStockBuffer.ItemInventoryQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ItemSoldNotPostedQty; format(TempStockBuffer.ItemSoldNotPostedQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ItemSoldTodayQty; format(TempStockBuffer.ItemSoldTodayQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(NetInventoryQty; format(TempStockBuffer.NetInventoryQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ShowVariant; RetailSetup."PLSPOS_Show Var for Report VIP") { }

=======
            column(ItemNo; Item."No.") { }
            column(Description_Item; Item.Description) { }
            column(BaseUOM_Item; Item."Base Unit of Measure") { }
            column(ItemInventoryQty; format(ItemInventoryQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ItemSoldNotPostedQty; format(ItemSoldNotPostedQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ItemSoldTodayQty; format(ItemSoldTodayQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(NetInventoryQty; format(NetInventoryQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ItemWaitedTransferQty; ItemWaitedTransferQty) { }
            column(SkipLine; SkipLine) { }
            column(ShowLot; ShowLot) { }
            column(ShowVariant; RetailSetup."PLSPOS_Show Var for Report VIP") { }

            dataitem(TempItemVariant; "Item Variant")
            {
                DataItemTableView = sorting("Item No.", Code);
                DataItemLink = "Item No." = field("No.");
                UseTemporary = true;

                column(Variant_Code; Code) { }

                trigger OnPreDataItem()
                begin
                    Clear(CurrLot);
                end;

                trigger OnAfterGetRecord()
                begin
                    Clear(SkipLine);
                    Clear(ItemInventoryQty);
                    Clear(ItemSoldTodayQty);
                    Clear(ItemSoldNotPostedQty);
                    Clear(ItemWaitedTransferQty);
                    Clear(NetInventoryQty);

                    // ── Item Inventory Qty จาก Item Ledger Entry ──
                    // ใช้ CalcSums — BC ทำเป็น SQL SUM ให้แล้ว
                    Clear(ItemLedgerEntryTB);
                    ItemLedgerEntryTB.SetCurrentKey("Item No.", "Posting date", "Location Code");
                    ItemLedgerEntryTB.SetRange("Item No.", Item."No.");
                    ItemLedgerEntryTB.SetRange("Posting Date", 0D, AsOfDateFilter);
                    ItemLedgerEntryTB.SetFilter("Location Code", LocationFilter);
                    ItemLedgerEntryTB.SetLoadFields("Item No.", "Posting Date", "Location Code",
                                                    "Variant Code", "Remaining Quantity");
                    if RetailSetup."PLSPOS_Show Var for Report VIP" then
                        ItemLedgerEntryTB.SetRange("Variant Code", Code);
                    ItemLedgerEntryTB.CalcSums("Remaining Quantity");
                    ItemInventoryQty := ItemLedgerEntryTB."Remaining Quantity";

                    // ── Sold Qty — ใช้ Store list ที่ Cache ไว้จาก OnPreDataItem ──
                    // ไม่ต้อง FindSet() ซ้ำทุก Variant ทุก Item
                    if LocationFilter <> '' then begin
                        if CachedStoreListReady then begin
                            // อ่านจาก Temp Store list ที่ build ไว้แล้ว
                            TempStoreTB.Reset();
                            if TempStoreTB.FindSet() then
                                repeat
                                    ItemSoldTodayQty += QtySoldNotPosted(Item."No.", TempStoreTB."No.", Code, Today, true, '');
                                    ItemSoldNotPostedQty += QtySoldNotPosted(Item."No.", TempStoreTB."No.", Code, Today - 1, false, '');
                                until TempStoreTB.Next() = 0;
                        end;
                    end else begin
                        ItemSoldTodayQty := QtySoldNotPosted(Item."No.", '', Code, Today, true, '');
                        ItemSoldNotPostedQty := QtySoldNotPosted(Item."No.", '', Code, Today - 1, false, '');
                    end;

                    NetInventoryQty := ItemInventoryQty + ItemSoldTodayQty + ItemSoldNotPostedQty;

                    if NetInventoryQty < 0 then
                        if not ShowNegativeFilter then
                            SkipLine := true;

                    if NetInventoryQty = 0 then
                        if not ShowZeroFilter then
                            SkipLine := true;
                end;
            }

>>>>>>> b8f4287c17910c5af2d2f36ad697bf69b2856e86
            trigger OnPreDataItem()
            var
                StoreTB: Record "LSC Store";
            begin
                AsOfDateFilter := Today;

                if LocationFilter = '' then
                    Error('Please input Location filter!');

                Clear(ReportFilterText);
<<<<<<< HEAD
                if (ItemNoFilter <> '') then
                    ReportFilterText += 'Item No. : ' + FORMAT(ItemNoFilter + ' ');

                if (LocationFilter <> '') then
=======
                if ItemNoFilter <> '' then begin
                    ReportFilterText += 'Item No. : ' + FORMAT(ItemNoFilter + ' ');
                    Item.SetFilter("No.", ItemNoFilter);
                end;
                if LocationFilter <> '' then
>>>>>>> b8f4287c17910c5af2d2f36ad697bf69b2856e86
                    ReportFilterText += ' Location : ' + FORMAT(LocationFilter + ' ');

                if DivisionFilter <> '' then begin
                    ReportFilterText += ' Division : ' + DivisionFilter;
                    if ItemCategoryFilter <> '' then
                        ReportFilterText += ' ItemCategoryFilter : ' + ItemCategoryFilter;
                    if ProductGroupFilter <> '' then
                        ReportFilterText += ' ProductGroupFilter : ' + ProductGroupFilter;
                end;
<<<<<<< HEAD

                if (ShowItemBlock) then
=======
                if ShowItemBlock then
>>>>>>> b8f4287c17910c5af2d2f36ad697bf69b2856e86
                    ReportFilterText += ' Show Item Blocked';
                if ShowZeroFilter then
                    ReportFilterText += ' Show Item Quantity Zero';
                if ShowNegativeFilter then
                    ReportFilterText += ' Show Negative Quantity';

                // ── Store filter text ──
                // StoreTB.Get() ใช้ "No." เป็น PK ไม่ใช่ Location Code
                // ต้อง SetFilter "Location Code" แล้ว FindFirst() แทน
                Clear(StoreTB);
                StoreTB.SetLoadFields("No.", Name, "Location Code");
                StoreTB.SetFilter("Location Code", LocationFilter);
                if StoreTB.FindFirst() then
                    StoreFilterText := StoreTB."No." + ' : ' + StoreTB.Name;

<<<<<<< HEAD
                //สั่งกวาดข้อมูลลง Temp Table
                BuildTempData();
=======
                if not ShowItemBlock then
                    SetRange(Item.Blocked, false);
                SetFilter(Item.Type, '%1', Type::Inventory);

                // ── Build Temp Store list ครั้งเดียว ──
                // แทนที่จะ FindSet() ซ้ำทุก Variant ทุก Item
                TempStoreTB.Reset();
                TempStoreTB.DeleteAll();
                CachedStoreListReady := false;

                if LocationFilter <> '' then begin
                    Clear(StoreTB);
                    StoreTB.SetLoadFields("No.", "Location Code");
                    StoreTB.SetFilter("Location Code", LocationFilter);
                    if StoreTB.FindSet() then begin
                        repeat
                            TempStoreTB.Init();
                            TempStoreTB.TransferFields(StoreTB);
                            TempStoreTB.Insert(false);
                        until StoreTB.Next() = 0;
                        CachedStoreListReady := true;
                    end;
                end;

                // ── Prefilter Item เฉพาะที่มีใน ILE ของ Location ที่เลือก ──
                if LocationFilter <> '' then begin
                    Clear(PreFilterILE);
                    PreFilterILE.SetCurrentKey("Item No.", "Location Code");
                    PreFilterILE.SetFilter("Location Code", LocationFilter);
                    PreFilterILE.SetLoadFields("Item No.", "Location Code");
                    Clear(PreFilterItemList);
                    Clear(PreFilterLastItemNo);
                    if PreFilterILE.FindSet() then begin
                        repeat
                            if PreFilterILE."Item No." <> PreFilterLastItemNo then begin
                                if PreFilterItemList = '' then
                                    PreFilterItemList := PreFilterILE."Item No."
                                else
                                    PreFilterItemList += '|' + PreFilterILE."Item No.";
                                PreFilterLastItemNo := PreFilterILE."Item No.";
                            end;
                        until PreFilterILE.Next() = 0;
                        SetFilter("No.", PreFilterItemList);
                    end else
                        CurrReport.Break();
                end;

                // โหลดเฉพาะ field ที่ใช้จริงของ Item
                SetLoadFields("No.", Description, "Base Unit of Measure",
                              Blocked, Type, "LSC Division Code",
                              "Item Category Code", "LSC Retail Product Code");
>>>>>>> b8f4287c17910c5af2d2f36ad697bf69b2856e86
            end;

            trigger OnAfterGetRecord()
            begin
<<<<<<< HEAD
                // เดินหน้าอ่านข้อมูลจาก Temp Table ทีละบรรทัด
                if Number = 1 then begin
                    TempStockBuffer.SetCurrentKey("Item No.", "Variant Code");
                    if not TempStockBuffer.FindSet() then
                        CurrReport.Break();
                end else begin
                    if TempStockBuffer.Next() = 0 then
                        CurrReport.Break();
=======
                Clear(SkipLine);
                Clear(ItemInventoryQty);
                Clear(ItemSoldTodayQty);
                Clear(ItemSoldNotPostedQty);
                Clear(ItemWaitedTransferQty);
                Clear(NetInventoryQty);

                Clear(TempItemVariant);
                TempItemVariant.DeleteAll();

                // ── Dummy variant (ไม่แยก variant) ──
                TempItemVariant.Init();
                TempItemVariant."Item No." := "No.";
                TempItemVariant.Insert(false);

                // ── ถ้าแสดง variant: ดึง Item Variant มาใส่ Temp ──
                if RetailSetup."PLSPOS_Show Var for Report VIP" then begin
                    Clear(ItemVariantTB);
                    ItemVariantTB.SetCurrentKey("Item No.", Code);
                    ItemVariantTB.SetRange("Item No.", "No.");
                    ItemVariantTB.SetLoadFields("Item No.", Code);
                    if ItemVariantTB.FindSet() then
                        repeat
                            TempItemVariant.Init();
                            TempItemVariant.TransferFields(ItemVariantTB);
                            TempItemVariant.Insert(false);
                        until ItemVariantTB.Next() = 0;
>>>>>>> b8f4287c17910c5af2d2f36ad697bf69b2856e86
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
                        //AVTNK	28/11/2024	add field , hide field
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
                        //C-AVTNK	28/11/2024	add field , hide field


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
<<<<<<< HEAD
=======

        trigger OnInit()
        begin
            Clear(ItemCategoryFilter);
            Clear(ProductGroupFilter);
        end;
>>>>>>> b8f4287c17910c5af2d2f36ad697bf69b2856e86
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
        TempStockBuffer: Record "PLSR_Store Stock Buffer" temporary;
        ComInfo: Record "Company Information";
        RetailSetup: Record "LSC Retail Setup";
<<<<<<< HEAD
        AsOfDateFilter: Date;
        LocationFilter: Code[20];
        LotFilter: Code[20];
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        VariantFilter: Code[20];
        DivisionFilter: Code[20];
        ItemCategoryFilter: Code[20];
        ProductGroupFilter: Code[20];
        SoldTodayFilter: Boolean;
        ShowItemBlock: Boolean;
        ShowZeroFilter: Boolean;
        ShowNegativeFilter: Boolean;
        ShowDate: Text;
        ShowTime: Text;
        ReportFilterText: Text;
        StoreFilterText: Text;

    local procedure BuildTempData()
    var
        ItemRecord: Record Item;
        ILEQuery: Query "PLSR_StoreStockILE_Q";
        SalesQuery: Query "PLSR_StoreStockTSE_Q";
        StatusQuery: Query "PLSR_StoreStockTSES_Q";
        QtySold: Decimal;
        QtyPosted: Decimal;
    begin
        TempStockBuffer.Reset();
        TempStockBuffer.DeleteAll();

        // --- STEP 1: กรอง Item (สร้างบรรทัดเดียวต่อ 1 รหัสสินค้า) ---
        ItemRecord.Reset();
        ItemRecord.SetFilter(Type, '%1', ItemRecord.Type::Inventory);

        if not ShowItemBlock then
            ItemRecord.SetRange(Blocked, false);

        if ItemNoFilter <> '' then
            ItemRecord.SetFilter("No.", ItemNoFilter);

        if DivisionFilter <> '' then
            ItemRecord.SetFilter("LSC Division Code", DivisionFilter);

        if ItemCategoryFilter <> '' then
            ItemRecord.SetFilter("Item Category Code", ItemCategoryFilter);

        if ProductGroupFilter <> '' then
            ItemRecord.SetFilter("LSC Retail Product Code", ProductGroupFilter);

        if ItemRecord.FindSet() then
            repeat
                TempStockBuffer.Init();
                TempStockBuffer."Item No." := ItemRecord."No.";
                TempStockBuffer."Variant Code" := '';
                TempStockBuffer.Description := ItemRecord.Description;
                TempStockBuffer."Base Unit of Measure" := ItemRecord."Base Unit of Measure";
                TempStockBuffer.Insert();
            until ItemRecord.Next() = 0;

        // --- STEP 2: ค้นหา Inventory จาก ILE (โกยยอดทุก Variant มารวมกัน) ---
        if ItemNoFilter <> '' then ILEQuery.SetFilter(Item_No, ItemNoFilter);

        // กรอง Variant ตาม Request Page (ถ้าตั้งค่าให้ใช้ได้)
        if RetailSetup."PLSPOS_Show Var for Report VIP" and (VariantFilter <> '') then
            ILEQuery.SetFilter(Variant_Code, VariantFilter);

        if LocationFilter <> '' then ILEQuery.SetFilter(Location_Code, LocationFilter);
        if LotFilter <> '' then ILEQuery.SetFilter(Lot_No, LotFilter);
        ILEQuery.SetFilter(Posting_Date, '<=%1', AsOfDateFilter);

        if ILEQuery.Open() then begin
            while ILEQuery.Read() do begin
                // โยนยอดของทุก Variant ที่ Query หาเจอมารวมกันในบรรทัด Item บรรทัดเดียว!
                if TempStockBuffer.Get(ILEQuery.Q_Item_No, '') then begin
                    TempStockBuffer.ItemInventoryQty += ILEQuery.Sum_Remaining_Qty;
                    TempStockBuffer.Modify();
                end;
            end;
            ILEQuery.Close();
        end;

        // --- STEP 3: ดึงยอดขายและสถานะ ---
        if TempStockBuffer.FindSet() then
            repeat
                QtySold := 0;
                QtyPosted := 0;

                Clear(SalesQuery);
                SalesQuery.SetRange(Item_No, TempStockBuffer."Item No.");
                if RetailSetup."PLSPOS_Show Var for Report VIP" and (VariantFilter <> '') then
                    SalesQuery.SetRange(Variant_Code, VariantFilter);
                if StoreFilter <> '' then
                    SalesQuery.SetFilter(Store_No, StoreFilter);

                SalesQuery.SetRange(Date_Filter, AsOfDateFilter);

                if SalesQuery.Open() then begin
                    if SalesQuery.Read() then
                        QtySold := SalesQuery.Sum_Quantity;
                    SalesQuery.Close();
                end;

                Clear(StatusQuery);
                StatusQuery.SetRange(Item_No, TempStockBuffer."Item No.");
                if RetailSetup."PLSPOS_Show Var for Report VIP" and (VariantFilter <> '') then
                    StatusQuery.SetRange(Variant_Code, VariantFilter);
                if StoreFilter <> '' then
                    StatusQuery.SetFilter(Store_No, StoreFilter);
                if LotFilter <> '' then
                    StatusQuery.SetFilter(Lot_No, LotFilter);

                StatusQuery.SetRange(Date_Filter, AsOfDateFilter);
                StatusQuery.SetFilter(Status, '%1|%2', 1, 2);

                if StatusQuery.Open() then begin
                    if StatusQuery.Read() then
                        QtyPosted := StatusQuery.Sum_Quantity;
                    StatusQuery.Close();
                end;

                TempStockBuffer.ItemSoldTodayQty := QtySold - QtyPosted;
                TempStockBuffer.ItemSoldNotPostedQty := 0;

                TempStockBuffer.NetInventoryQty := TempStockBuffer.ItemInventoryQty - TempStockBuffer.ItemSoldTodayQty - TempStockBuffer.ItemSoldNotPostedQty;
                TempStockBuffer.Modify();

            until TempStockBuffer.Next() = 0;

        if TempStockBuffer.FindSet() then
            repeat
                if (TempStockBuffer.NetInventoryQty < 0) and (not ShowNegativeFilter) then
                    TempStockBuffer.Delete()
                else if (TempStockBuffer.NetInventoryQty = 0) and (not ShowZeroFilter) then
                    TempStockBuffer.Delete();
            until TempStockBuffer.Next() = 0;
=======

        // ── Temp Store list — build ครั้งเดียวใน OnPreDataItem ──
        // แทนที่จะ FindSet() ซ้ำทุก Variant ทุก Item
        TempStoreTB: Record "LSC Store" temporary;
        CachedStoreListReady: Boolean;

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
        PreFilterILE: Record "Item Ledger Entry";
        PreFilterItemList: Text;
        PreFilterLastItemNo: Code[20];
        ShowZeroFilter: Boolean;
        ShowNegativeFilter: Boolean;
        ShowItemBlock: Boolean;
        SkipLine: Boolean;
        ShowLot: Boolean;
        CurrLot: Text[50];
        DivisionFilter: Code[20];
        ItemCategoryFilter: Code[20];
        ProductGroupFilter: Code[20];

    local procedure QtySoldNotPosted(ItemNo: Code[20];
                             StoreFilter: Code[250];
                             VariantFilter: Code[250];
                             DateFilter: Date;
                             SoldTodayFilter: Boolean;
                             LotFilter: Code[50]) QtySoldNotPosted: Decimal
    var
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        TransSalesEntryStatus: Record "LSC Trans. Sales Entry Status";
        QuantitySold: Decimal;
        QuantityPosted: Decimal;
    begin
        Clear(QuantitySold);
        Clear(QuantityPosted);
        Clear(QtySoldNotPosted);

        // ── Trans. Sales Entry ──
        Clear(TransSalesEntry);
        TransSalesEntry.SetCurrentKey("Item No.", "Variant Code", Date);
        TransSalesEntry.SetRange("Item No.", ItemNo);
        TransSalesEntry.SetLoadFields("Item No.", "Variant Code", Date, "Store No.", Quantity, "Lot No.");
        if LotFilter <> '' then
            TransSalesEntry.SetRange("Lot No.", LotFilter);
        if RetailSetup."PLSPOS_Show Var for Report VIP" then
            TransSalesEntry.SetFilter("Variant Code", VariantFilter);
        if StoreFilter <> '' then
            TransSalesEntry.SetFilter("Store No.", StoreFilter);
        if SoldTodayFilter then
            TransSalesEntry.SetRange(Date, DateFilter)
        else
            TransSalesEntry.SetRange(Date, 0D, DateFilter);
        TransSalesEntry.CalcSums(Quantity);
        QuantitySold := TransSalesEntry.Quantity;

        // ── Trans. Sales Entry Status ──
        Clear(TransSalesEntryStatus);
        TransSalesEntryStatus.SetCurrentKey("Item No.", "Variant Code", Status, "Store No.", Date);
        TransSalesEntryStatus.SetRange("Item No.", ItemNo);
        TransSalesEntryStatus.SetLoadFields("Item No.", "Variant Code", Status, "Store No.", Date, Quantity, "Lot No.");
        if RetailSetup."PLSPOS_Show Var for Report VIP" then
            TransSalesEntryStatus.SetFilter("Variant Code", VariantFilter);
        if SoldTodayFilter then
            TransSalesEntryStatus.SetRange(Date, DateFilter)
        else
            TransSalesEntryStatus.SetRange(Date, 0D, DateFilter);
        TransSalesEntryStatus.SetRange(Status,
            TransSalesEntryStatus.Status::"Items Posted",
            TransSalesEntryStatus.Status::Posted);
        if StoreFilter <> '' then
            TransSalesEntryStatus.SetFilter("Store No.", StoreFilter);
        if LotFilter <> '' then
            TransSalesEntryStatus.SetRange("Lot No.", LotFilter);
        TransSalesEntryStatus.CalcSums(Quantity);
        QuantityPosted := TransSalesEntryStatus.Quantity;

        QtySoldNotPosted := QuantitySold - QuantityPosted;
>>>>>>> b8f4287c17910c5af2d2f36ad697bf69b2856e86
    end;

    procedure SetLocationFilter(refLocationFilter: Code[20])
    begin
        LocationFilter := refLocationFilter;
    end;

    procedure SetNegativeFilter(refShowNegativeFilter: Boolean)
    begin
        ShowNegativeFilter := refShowNegativeFilter;
    end;
    // C-AVPWDLSVIP 26/06/2025 > Improve Performance of VIP Report(76081) น้องอิง
}