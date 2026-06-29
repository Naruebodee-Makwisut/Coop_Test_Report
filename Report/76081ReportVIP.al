report 50105 "Store Stock Checking"
{
    Caption = 'Store Stock Checking';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50105_StoreStockChecking.rdl';
    PreviewMode = PrintLayout;
    // AVPWDLSVIP 26/06/2025 > Improve Performance of VIP Report(76081) น้องอิง

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;

            column(StoreNo_Name_StoreTB; StoreFilterText) { }
            column(ReportFilterText; ReportFilterText) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
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

            trigger OnPreDataItem()
            begin
                AsOfDateFilter := Today;

                if LocationFilter = '' then
                    Error('Please input Location filter!');

                Clear(ReportFilterText);
                if ItemNoFilter <> '' then begin
                    ReportFilterText += 'Item No. : ' + FORMAT(ItemNoFilter + ' ');
                    Item.SetFilter("No.", ItemNoFilter);
                end;
                if LocationFilter <> '' then
                    ReportFilterText += ' Location : ' + FORMAT(LocationFilter + ' ');
                if DivisionFilter <> '' then begin
                    ReportFilterText += ' Division : ' + DivisionFilter;
                    SetFilter("LSC Division Code", DivisionFilter);
                    if ItemCategoryFilter <> '' then
                        ReportFilterText += ' ItemCategoryFilter :' + ItemCategoryFilter;
                    SetFilter("Item Category Code", ItemCategoryFilter);
                    if ProductGroupFilter <> '' then
                        ReportFilterText += 'ProductGroupFilter :' + ProductGroupFilter;
                    SetFilter("LSC Retail Product Code", ProductGroupFilter);
                end;
                if ShowItemBlock then
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
        ItemVariantTB: Record "Item Variant";
        RetailSetup: Record "LSC Retail Setup";

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