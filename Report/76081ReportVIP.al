report 50105 "Store Stock Checking"
{
    Caption = 'Store Stock Checking';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50105_StoreStockChecking.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem(Item; Item)
        {
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
            end;

            trigger OnAfterGetRecord()
            begin
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
        trigger OnInit()
        begin
            //AVTNK	29/11/2024	Clear   
            Clear(ItemCategoryFilter);
            Clear(ProductGroupFilter);
            //C-AVTNK	28/11/2024
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
        ItemVariantTB: Record "Item Variant";
        RetailSetup: Record "LSC Retail Setup";

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
    begin
        LocationFilter := refLocationFilter;
    end;

    procedure SetNegativeFilter(refShowNegativeFilter: Boolean)
    begin
        ShowNegativeFilter := refShowNegativeFilter;
    end;
}