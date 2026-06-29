report 50110 "PLSR_Store Stock Checking 2"
{
    Caption = 'Store Stock Checking';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50105_StoreStockChecking.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem(ReportHeader; Integer)
        {
<<<<<<< HEAD
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            column(StoreNo_Name_StoreTB; StoreFilterText)
            { }
            column(ReportFilterText; ReportFilterText)
            { }
            column(ShowDate; ShowDate)
            { }
            column(ShowTime; ShowTime)
            { }
            column(ItemNo; Item."No.")
            { }
            column(Description_Item; Item.Description)
            { }
            column(BaseUOM_Item; Item."Base Unit of Measure")
            { }
            column(ItemInventoryQty; format(ItemInventoryQty, 0, '<Sign><Integer Thousand><Decimals>'))
            { }
            column(ItemSoldNotPostedQty; format(ItemSoldNotPostedQty, 0, '<Sign><Integer Thousand><Decimals>'))
            { }
            column(ItemSoldTodayQty; format(ItemSoldTodayQty, 0, '<Sign><Integer Thousand><Decimals>'))
            { }
            column(NetInventoryQty; format(NetInventoryQty, 0, '<Sign><Integer Thousand><Decimals>'))
            { }
            column(ItemWaitedTransferQty; ItemWaitedTransferQty)
            { }
            column(SkipLine; SkipLine)
            { }
            column(ShowLot; ShowLot)
            { }
            column(ShowVariant; RetailSetup."PLSPOS_Show Var for Report VIP")
            { }


            dataitem(TempItemVariant; "Item Variant")
            {
                DataItemTableView = sorting("Item No.", Code);
                DataItemLink = "Item No." = field("No.");
                UseTemporary = true;

                // column(Lot_No; "Item Ledger Entry"."Lot No.")
                // { }
                column(Variant_Code; Code)
                { }

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

                    //find Item Inventory Qty.
                    Clear(ItemLedgerEntryTB);
                    ItemLedgerEntryTB.SetCurrentKey("Item No.", "Posting date", "Location Code");
                    ItemLedgerEntryTB.SetRange("Item No.", Item."No.");
                    ItemLedgerEntryTB.SetRange("Posting Date", 0D, AsOfDateFilter);
                    ItemLedgerEntryTB.SetFilter("Location Code", LocationFilter);
                    ItemLedgerEntryTB.SetLoadFields("Item No.", "Posting Date", "Location Code",
                                                     "Variant Code", "Remaining Quantity");

                    if RetailSetup."PLSPOS_Show Var for Report VIP" then //table RetailSetupเช็ค varcode เพราะถ้าเปิด ture จะแสดงด้วย
                        ItemLedgerEntryTB.SetRange("Variant Code", Code);
                    ItemLedgerEntryTB.CalcSums("Remaining Quantity");
                    ItemInventoryQty := ItemLedgerEntryTB."Remaining Quantity";

                    // ── ใช้ store list ที่ cache ไว้จาก OnPreDataItem ──
                    // เดิม FindSet() ตาราง Store ใหม่ทุก Item x Variant (148,508 ครั้ง!)
                    // ตอนนี้ loop ผ่าน temp table ที่ build ไว้ครั้งเดียว
                    if LocationFilter <> '' then begin
                        if CachedStoreListReady then begin
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
                        if not ShowNegativeFilter then begin
                            CurrReport.Skip();
                            exit;
                        end;

                    if NetInventoryQty = 0 then
                        if not ShowZeroFilter then begin
                            CurrReport.Skip();
                            exit;
                        end;
                end;
            }




            trigger OnPreDataItem()
            begin

                AsOfDateFilter := Today;
                //check filter by location
                if LocationFilter = '' then
                    Error('Please input Location filter!');
                //check filter by location - end
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
                    //AVTNK	28/11/2024	add in trigger 
                    if ItemCategoryFilter <> '' then
                        ReportFilterText += ' ItemCategoryFilter :' + ItemCategoryFilter;
                    SetFilter("Item Category Code", ItemCategoryFilter);
                    if ProductGroupFilter <> '' then
                        ReportFilterText += 'ProductGroupFilter :' + ProductGroupFilter;
                    SetFilter("LSC Retail Product Code", ProductGroupFilter);
                    //C-AVTNK	28/11/2024	add in trigger 
                end;
                if (ShowItemBlock) then
                    ReportFilterText += ' Show Item Blocked';
                if (ShowZeroFilter) then
                    ReportFilterText += ' Show Item Quantity Zero';
                if ShowNegativeFilter then
                    ReportFilterText += ' Show Negative Quantity';
                Clear(StoreTB);
                StoreTB.SetLoadFields("No.", Name, "Location Code");
                StoreTB.SetFilter("Location Code", LocationFilter);
                if StoreTB.FindFirst() then
                    StoreFilterText := StoreTB."No." + ' : ' + StoreTB.Name;

                if not ShowItemBlock then
                    SetRange(Item.Blocked, false);
                SetFilter(Item.Type, '%1', Type::Inventory);

                // ── Build store list ครั้งเดียว (เดิม FindSet() ใหม่ทุก Item x Variant) ──
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

                // ── โหลดเฉพาะ field ที่ใช้จริงของ Item ──
                // หมายเหตุ: ไม่ทำ prefilter Item ด้วย ILE เพราะรายงานนี้ต้องจับ
                // item ที่ "ขายแล้วแต่ยังไม่ post เข้า ILE" ได้ด้วย (ดูคอลัมน์ Sold Not Posted)
                // ถ้า prefilter ด้วย ILE อย่างเดียวจะตัด item เหล่านี้หายไปจากรายงาน
                SetLoadFields("No.", Description, "Base Unit of Measure",
                              Blocked, Type, "LSC Division Code",
                              "Item Category Code", "LSC Retail Product Code");

                if not ShowZeroFilter then
                    SetFilter("No.", GetActiveItemFilter());
=======
            DataItemTableView = sorting(Number) where(Number = const(1));
            trigger OnPreDataItem()
            begin
                BuildTempData();
            end;
        }

        dataitem(BufferLoop; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(StoreNo_Name_StoreTB; StoreFilterText) { }
            column(ReportFilterText; ReportFilterText) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }

            column(ItemNo; ItemTB."No. 2") { }
            column(Description_Item; ItemTB.Description) { }
            column(BaseUOM_Item; ItemTB."Base Unit of Measure") { }
            column(Variant_Code; ItemTB."Vendor Item No.") { }

            column(ItemInventoryQty; format(ItemTB."Unit Price", 0, '<Sign><Integer Thousand>')) { }
            column(ItemSoldTodayQty; format(ItemTB."Unit Cost", 0, '<Sign><Integer Thousand>')) { }
            column(ItemSoldNotPostedQty; format(ItemTB."Standard Cost", 0, '<Sign><Integer Thousand>')) { }
            column(NetInventoryQty; format(ItemTB."Last Direct Cost", 0, '<Sign><Integer Thousand>')) { }
            column(ShowVariant; RetailSetup."PLSPOS_Show Var for Report VIP") { }

            trigger OnPreDataItem()
            begin
                ComInfo.Get();
                ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                ShowTime := LSVIPRepFucntion.AVTimeFormat(Time);

                ItemTB.Reset();
                ItemTB.SetCurrentKey("Search Description");
                ItemTB.Ascending(true);
                SetRange(Number, 1, ItemTB.Count());
                if ItemTB.IsEmpty() then
                    CurrReport.Break();
>>>>>>> origin/1-test
            end;

            trigger OnAfterGetRecord()
            begin
<<<<<<< HEAD
                Clear(SkipLine);
                Clear(ItemInventoryQty);
                Clear(ItemSoldTodayQty);
                Clear(ItemSoldNotPostedQty);
                Clear(ItemWaitedTransferQty);
                Clear(NetInventoryQty);

                Clear(TempItemVariant);
                TempItemVariant.DeleteAll();

                TempItemVariant.Init();
                TempItemVariant."Item No." := "No.";
                TempItemVariant.Insert(false);

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
=======
                if Number = 1 then begin
                    if not ItemTB.FindSet() then
                        CurrReport.Break();
                end else begin
                    if ItemTB.Next() = 0 then
                        CurrReport.Break();
>>>>>>> origin/1-test
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
        trigger OnInit()
        begin
            //AVTNK	29/11/2024	Clear   
            Clear(ItemCategoryFilter);
            Clear(ProductGroupFilter);
            //C-AVTNK	28/11/2024
        end;




=======
>>>>>>> origin/1-test
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
        ItemTB: Record "Item" temporary;
        ComInfo: Record "Company Information";
        RetailSetup: Record "LSC Retail Setup";
<<<<<<< HEAD

        // ── Temp store list — build ครั้งเดียวใน OnPreDataItem ──
        TempStoreTB: Record "LSC Store" temporary;
        CachedStoreListReady: Boolean;

        ShowTime: Text[50];
        ShowDate: Text[50];
        ReportFilterText: Text[250];
        StoreFilterText: Text[250];
        ItemNoFilter: Code[20];

        LocationFilter: Code[20];
        //OldItemNo: Code[20];
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
        CurrLot: Text[50];
        DivisionFilter: Code[20];

        //AVTNK	28/11/2024 add variable
        ItemCategoryFilter: Code[20];

        ProductGroupFilter: code[20];
    //C-AVTNK 28/11/2024 add variable
=======
        AsOfDateFilter: Date;
        LocationFilter, ItemNoFilter, DivisionFilter, ItemCategoryFilter, ProductGroupFilter : Code[20];
        ShowItemBlock, ShowZeroFilter, ShowNegativeFilter : Boolean;
        ShowDate, ShowTime, ReportFilterText, StoreFilterText : Text;
>>>>>>> origin/1-test

    local procedure BuildTempData()
    var
        ItemRecord: Record Item;
        ItemVariant: Record "Item Variant";
        StoreTB: Record "LSC Store";
        ILEQuery: Query "PLSR_StoreStockILE_Q";
        SalesQuery: Query "PLSR_StoreStockTSE_Q";
        StatusQuery: Query "PLSR_StoreStockTSES_Q";
        EntryNo: Integer;
        StoreFilterString: Text;
        ShowVar: Boolean;
    begin
<<<<<<< HEAD
        CLEAR(QuantitySold);
        CLEAR(QuantityPosted);
        CLEAR(QtySoldNotPosted);
        CLEAR(TransSalesEntry);
        TransSalesEntry.SETCURRENTKEY("Item No.", "Variant Code", Date);
        TransSalesEntry.SETRANGE("Item No.", ItemNo);
        TransSalesEntry.SetLoadFields("Item No.", "Variant Code", Date, "Store No.", Quantity, "Lot No.");
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
        // end;

        CLEAR(TransSalesEntryStatus);
        TransSalesEntryStatus.SETCURRENTKEY("Item No.", "Variant Code", Status, "Store No.", Date);
        TransSalesEntryStatus.SETRANGE("Item No.", ItemNo);
        TransSalesEntryStatus.SetLoadFields("Item No.", "Variant Code", Status, "Store No.", Date, Quantity, "Lot No.");
        IF RetailSetup."PLSPOS_Show Var for Report VIP" THEN
            TransSalesEntryStatus.SETFILTER("Variant Code", VariantFilter);
        IF SoldTodayFilter THEN
            TransSalesEntryStatus.SETRANGE(Date, DateFilter)
        ELSE
            TransSalesEntryStatus.SETRANGE(Date, 0D, DateFilter);
        TransSalesEntryStatus.SETRANGE(Status, TransSalesEntryStatus.Status::"Items Posted",
          TransSalesEntryStatus.Status::Posted);
        IF StoreFilter <> '' THEN
            TransSalesEntryStatus.SETFILTER("Store No.", StoreFilter);
        if LotFilter <> '' then
            TransSalesEntryStatus.SetRange("Lot No.", LotFilter);
        TransSalesEntryStatus.CalcSums(Quantity);
        QuantityPosted := TransSalesEntryStatus.Quantity;
        QtySoldNotPosted := QuantitySold - QuantityPosted;
    end;

    local procedure GetActiveItemFilter(): Text
    var
        ILE: Record "Item Ledger Entry";
        TSE: Record "LSC Trans. Sales Entry";
        ActiveItems: Dictionary of [Code[20], Boolean];
        ItemNo: Code[20];
        FilterText: Text;
        StoreFilter: Text;
    begin
        StoreFilter := BuildStoreFilterText();

        ILE.SetCurrentKey("Item No.", "Posting Date", "Location Code");
        ILE.SetRange("Posting Date", 0D, AsOfDateFilter);
        ILE.SetFilter("Location Code", LocationFilter);
        ILE.SetLoadFields("Item No.", "Remaining Quantity");
        if ILE.FindSet() then
            repeat
                if ILE."Remaining Quantity" <> 0 then
                    if not ActiveItems.ContainsKey(ILE."Item No.") then
                        ActiveItems.Add(ILE."Item No.", true);
            until ILE.Next() = 0;

        TSE.SetCurrentKey("Item No.", "Variant Code", Date);
        TSE.SetRange(Date, 0D, Today);
        if StoreFilter <> '' then
            TSE.SetFilter("Store No.", StoreFilter);
        TSE.SetLoadFields("Item No.", Quantity);
        if TSE.FindSet() then
            repeat
                if TSE.Quantity <> 0 then
                    if not ActiveItems.ContainsKey(TSE."Item No.") then
                        ActiveItems.Add(TSE."Item No.", true);
            until TSE.Next() = 0;

        foreach ItemNo in ActiveItems.Keys() do begin
            if FilterText <> '' then
                FilterText += '|';
            FilterText += ItemNo;
        end;
        exit(FilterText);
    end;

    local procedure BuildStoreFilterText(): Text
    var
        FilterText: Text;
    begin
        TempStoreTB.Reset();
        if TempStoreTB.FindSet() then
            repeat
                if FilterText <> '' then
                    FilterText += '|';
                FilterText += TempStoreTB."No.";
            until TempStoreTB.Next() = 0;
        exit(FilterText);
    end;

    procedure SetLocationFilter(refLocationFilter: Code[20])
=======
        if LocationFilter = '' then
            Error('Please input Location filter!');

        // --- เตรียม Report Filter Text ---
        Clear(ReportFilterText);
        if (ItemNoFilter <> '') then ReportFilterText += 'Item No. : ' + FORMAT(ItemNoFilter + ' ');
        if (LocationFilter <> '') then ReportFilterText += ' Location : ' + FORMAT(LocationFilter + ' ');
        if DivisionFilter <> '' then ReportFilterText += ' Division : ' + DivisionFilter;
        if ItemCategoryFilter <> '' then ReportFilterText += ' ItemCategoryFilter : ' + ItemCategoryFilter;
        if ProductGroupFilter <> '' then ReportFilterText += ' ProductGroupFilter : ' + ProductGroupFilter;
        if (ShowItemBlock) then ReportFilterText += ' Show Item Blocked';
        if (ShowZeroFilter) then ReportFilterText += ' Show Item Quantity Zero';
        if (ShowNegativeFilter) then ReportFilterText += ' Show Negative Quantity';

        Clear(StoreTB);
        if StoreTB.Get(LocationFilter) then
            StoreFilterText := StoreTB."No." + ' : ' + StoreTB.Name;

        ItemTB.Reset();
        ItemTB.DeleteAll();
        EntryNo := 0;
        AsOfDateFilter := Today;
        ShowVar := RetailSetup."PLSPOS_Show Var for Report VIP";

        StoreFilterString := '';
        StoreTB.Reset();
        StoreTB.SetFilter("Location Code", LocationFilter);
        if StoreTB.FindSet() then
            repeat
                if StoreFilterString <> '' then
                    StoreFilterString += '|';
                StoreFilterString += StoreTB."No.";
            until StoreTB.Next() = 0;
        if StoreFilterString = '' then StoreFilterString := '___NONE___';

        // ---  STEP 1: กวาดสินค้ากรณีเปิด Show Zero (กรองละเอียดตั้งแต่รอบแรก) ---
        if ShowZeroFilter then begin
            ItemRecord.Reset();
            ItemRecord.SetRange(Type, ItemRecord.Type::Inventory);
            if not ShowItemBlock then ItemRecord.SetRange(Blocked, false);
            if ItemNoFilter <> '' then ItemRecord.SetFilter("No.", ItemNoFilter);
            if DivisionFilter <> '' then ItemRecord.SetFilter("LSC Division Code", DivisionFilter);
            if ItemCategoryFilter <> '' then ItemRecord.SetFilter("Item Category Code", ItemCategoryFilter);
            if ProductGroupFilter <> '' then ItemRecord.SetFilter("LSC Retail Product Code", ProductGroupFilter);
            if ItemRecord.FindSet() then
                repeat
                    if ShowVar then begin
                        FindOrCreateItemTB(ItemRecord."No.", '', ItemRecord.Description, ItemRecord."Base Unit of Measure", ItemTB, EntryNo, ShowVar);
                        ItemVariant.Reset();
                        ItemVariant.SetRange("Item No.", ItemRecord."No.");
                        if ItemVariant.FindSet() then
                            repeat
                                FindOrCreateItemTB(ItemRecord."No.", ItemVariant.Code, ItemRecord.Description, ItemRecord."Base Unit of Measure", ItemTB, EntryNo, ShowVar);
                            until ItemVariant.Next() = 0;
                    end else begin
                        FindOrCreateItemTB(ItemRecord."No.", '', ItemRecord.Description, ItemRecord."Base Unit of Measure", ItemTB, EntryNo, ShowVar);
                    end;
                until ItemRecord.Next() = 0;
        end;

        // ---  STEP 2: ดึงยอดคงคลังสุทธิ (ILE) + ยัดฟิลเตอร์เข้าตัว Query ตรงๆ เพื่อความเร็วระดับ SQL ---
        Clear(ILEQuery);
        if ItemNoFilter <> '' then ILEQuery.SetFilter(Item_No, ItemNoFilter);
        if LocationFilter <> '' then ILEQuery.SetFilter(Location_Code, LocationFilter);
        ILEQuery.SetFilter(Posting_Date, '<=%1', AsOfDateFilter);
        if not ShowItemBlock then ILEQuery.SetRange(Is_Blocked, false);
        if DivisionFilter <> '' then ILEQuery.SetFilter(Division_Code, DivisionFilter);
        if ItemCategoryFilter <> '' then ILEQuery.SetFilter(Item_Category, ItemCategoryFilter);
        if ProductGroupFilter <> '' then ILEQuery.SetFilter(Product_Group, ProductGroupFilter);

        if ILEQuery.Open() then begin
            while ILEQuery.Read() do begin
                if FindOrCreateItemTB(ILEQuery.Q_Item_No, ILEQuery.Q_Variant_Code, ILEQuery.Item_Desc, ILEQuery.Base_UOM, ItemTB, EntryNo, ShowVar) then begin
                    ItemTB."Unit Price" += ILEQuery.Sum_Remaining_Qty;
                    ItemTB.Modify();
                end;
            end;
            ILEQuery.Close();
        end;

        // ---  STEP 3: ดึงยอดขายของวันนี้ ---
        Clear(SalesQuery);
        SalesQuery.SetRange(Date_Filter, Today);
        SalesQuery.SetFilter(Store_No, StoreFilterString);
        if ItemNoFilter <> '' then SalesQuery.SetFilter(Item_No, ItemNoFilter);
        if not ShowItemBlock then SalesQuery.SetRange(Is_Blocked, false);
        if DivisionFilter <> '' then SalesQuery.SetFilter(Division_Code, DivisionFilter);
        if ItemCategoryFilter <> '' then SalesQuery.SetFilter(Item_Category, ItemCategoryFilter);
        if ProductGroupFilter <> '' then SalesQuery.SetFilter(Product_Group, ProductGroupFilter);

        if SalesQuery.Open() then begin
            while SalesQuery.Read() do begin
                if FindOrCreateItemTB(SalesQuery.Q_Item_No, SalesQuery.Q_Variant_Code, SalesQuery.Item_Desc, SalesQuery.Base_UOM, ItemTB, EntryNo, ShowVar) then begin
                    ItemTB."Unit Cost" += SalesQuery.Sum_Quantity;
                    ItemTB.Modify();
                end;
            end;
            SalesQuery.Close();
        end;

        Clear(StatusQuery);
        StatusQuery.SetRange(Date_Filter, Today);
        StatusQuery.SetFilter(Status, '%1|%2', 1, 2);
        StatusQuery.SetFilter(Store_No, StoreFilterString);
        if ItemNoFilter <> '' then StatusQuery.SetFilter(Item_No, ItemNoFilter);
        if not ShowItemBlock then StatusQuery.SetRange(Is_Blocked, false);
        if DivisionFilter <> '' then StatusQuery.SetFilter(Division_Code, DivisionFilter);
        if ItemCategoryFilter <> '' then StatusQuery.SetFilter(Item_Category, ItemCategoryFilter);
        if ProductGroupFilter <> '' then StatusQuery.SetFilter(Product_Group, ProductGroupFilter);

        if StatusQuery.Open() then begin
            while StatusQuery.Read() do begin
                if FindOrCreateItemTB(StatusQuery.Q_Item_No, StatusQuery.Q_Variant_Code, StatusQuery.Item_Desc, StatusQuery.Base_UOM, ItemTB, EntryNo, ShowVar) then begin
                    ItemTB."Unit Cost" -= StatusQuery.Sum_Quantity;
                    ItemTB.Modify();
                end;
            end;
            StatusQuery.Close();
        end;

        // ---  STEP 4: ดึงยอดขายในอดีต ---
        Clear(SalesQuery);
        SalesQuery.SetFilter(Date_Filter, '<%1', Today);
        SalesQuery.SetFilter(Store_No, StoreFilterString);
        if ItemNoFilter <> '' then SalesQuery.SetFilter(Item_No, ItemNoFilter);
        if not ShowItemBlock then SalesQuery.SetRange(Is_Blocked, false);
        if DivisionFilter <> '' then SalesQuery.SetFilter(Division_Code, DivisionFilter);
        if ItemCategoryFilter <> '' then SalesQuery.SetFilter(Item_Category, ItemCategoryFilter);
        if ProductGroupFilter <> '' then SalesQuery.SetFilter(Product_Group, ProductGroupFilter);

        if SalesQuery.Open() then begin
            while SalesQuery.Read() do begin
                if FindOrCreateItemTB(SalesQuery.Q_Item_No, SalesQuery.Q_Variant_Code, SalesQuery.Item_Desc, SalesQuery.Base_UOM, ItemTB, EntryNo, ShowVar) then begin
                    ItemTB."Standard Cost" += SalesQuery.Sum_Quantity;
                    ItemTB.Modify();
                end;
            end;
            SalesQuery.Close();
        end;

        Clear(StatusQuery);
        StatusQuery.SetFilter(Date_Filter, '<%1', Today);
        StatusQuery.SetFilter(Status, '%1|%2', 1, 2);
        StatusQuery.SetFilter(Store_No, StoreFilterString);
        if ItemNoFilter <> '' then StatusQuery.SetFilter(Item_No, ItemNoFilter);
        if not ShowItemBlock then StatusQuery.SetRange(Is_Blocked, false);
        if DivisionFilter <> '' then StatusQuery.SetFilter(Division_Code, DivisionFilter);
        if ItemCategoryFilter <> '' then StatusQuery.SetFilter(Item_Category, ItemCategoryFilter);
        if ProductGroupFilter <> '' then StatusQuery.SetFilter(Product_Group, ProductGroupFilter);

        if StatusQuery.Open() then begin
            while StatusQuery.Read() do begin
                if FindOrCreateItemTB(StatusQuery.Q_Item_No, StatusQuery.Q_Variant_Code, StatusQuery.Item_Desc, StatusQuery.Base_UOM, ItemTB, EntryNo, ShowVar) then begin
                    ItemTB."Standard Cost" -= StatusQuery.Sum_Quantity;
                    ItemTB.Modify();
                end;
            end;
            StatusQuery.Close();
        end;

        // ---  STEP 5: คำนวณยอดสุทธิใน Memory (ข้อมูลคลีนหมดจดแล้ว ไม่มีการยิง SQL GET อีกต่อไป!) ---
        ItemTB.Reset();
        if ItemTB.FindSet() then
            repeat
                ItemTB."Last Direct Cost" := ItemTB."Unit Price" + ItemTB."Unit Cost" + ItemTB."Standard Cost";
                ItemTB.Modify();
            until ItemTB.Next() = 0;

        // --- STEP 6: กรองค่าศูนย์และค่าติดลบ ---
        if not ShowZeroFilter then begin
            ItemTB.SetRange("Last Direct Cost", 0);
            if not ItemTB.IsEmpty() then ItemTB.DeleteAll();
            ItemTB.SetRange("Last Direct Cost");
        end;
        if not ShowNegativeFilter then begin
            ItemTB.SetFilter("Last Direct Cost", '<0');
            if not ItemTB.IsEmpty() then ItemTB.DeleteAll();
            ItemTB.SetRange("Last Direct Cost");
        end;

        ItemTB.Reset();
    end;

    // แก้ไขฟังก์ชันให้รับชื่อและหน่วยนับมาหยอดเข้า Temporary Table ทันทีที่ถูกสร้าง
    local procedure FindOrCreateItemTB(ItemNo: Code[20]; VariantCode: Code[20]; ItemDesc: Text[100]; BaseUOM: Code[10]; var ItemTB: Record Item temporary; var EntryNo: Integer; ShowVar: Boolean): Boolean
    var
        SearchKey: Code[100];
>>>>>>> origin/1-test
    begin
        if not ShowVar then
            VariantCode := '';

        SearchKey := CopyStr(ItemNo + '|' + VariantCode, 1, 100);
        ItemTB.Reset();
        ItemTB.SetCurrentKey("Search Description");
        ItemTB.SetRange("Search Description", SearchKey);
        if ItemTB.FindFirst() then begin
            // กรณีมีความจำเป็นต้องอัปเดตข้อมูลรายละเอียดเพิ่มเติม
            if (ItemTB.Description = '') and (ItemDesc <> '') then begin
                ItemTB.Description := ItemDesc;
                ItemTB."Base Unit of Measure" := BaseUOM;
                ItemTB.Modify();
            end;
            exit(true);
        end;

        EntryNo += 1;
        ItemTB.Init();
        ItemTB."No." := Format(EntryNo);
        ItemTB."No. 2" := ItemNo;
        ItemTB."Vendor Item No." := VariantCode;
        ItemTB."Search Description" := SearchKey;
        ItemTB.Description := ItemDesc;
        ItemTB."Base Unit of Measure" := BaseUOM;
        ItemTB.Insert();
        exit(true);
    end;
}