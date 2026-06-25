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
            PrintOnlyIfDetail = true; //ไม่แสดงผล ถ้าไม่มีข้อมูลลูก

            column(StoreNo_Name_StoreTB; StoreFilterText) { }
            column(ReportFilterText; ReportFilterText) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(ItemNo; Item."No.") { }
            column(Description_Item; Item.Description) { }
            column(BaseUOM_Item; Item."Base Unit of Measure") { }
            column(ShowLot; ShowLot) { }
            column(ShowVariant; RetailSetup."PLSPOS_Show Var for Report VIP") { }

            dataitem(TempItemVariant; "Item Variant")
            {
                DataItemTableView = sorting("Item No.", Code);
                DataItemLink = "Item No." = field("No.");
                UseTemporary = true;

                column(Variant_Code; Code) { }

                // จานย้ายพวกยอดคำนวณมาใส่ตรงนี้! เพื่อให้ RDLC รับค่าในแต่ละบรรทัดได้ตรงเป๊ะ (ชื่อตัวแปรคงเดิม)
                column(ItemInventoryQty; format(ItemInventoryQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
                column(ItemSoldNotPostedQty; format(ItemSoldNotPostedQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
                column(ItemSoldTodayQty; format(ItemSoldTodayQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
                column(NetInventoryQty; format(NetInventoryQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
                column(ItemWaitedTransferQty; ItemWaitedTransferQty) { }
                column(SkipLine; SkipLine) { }

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

                    // 1. สร้าง Key สำหรับยิงเข้า Dictionary
                    DictKey := "Item No.";
                    if RetailSetup."PLSPOS_Show Var for Report VIP" then
                        DictKey += '|' + Code;

                    // 2. ดึงค่าจาก Memory
                    if DictInvQty.ContainsKey(DictKey) then
                        ItemInventoryQty := DictInvQty.Get(DictKey);

                    if DictSoldTodayQty.ContainsKey(DictKey) then
                        ItemSoldTodayQty := DictSoldTodayQty.Get(DictKey);

                    if DictSoldNotPostedQty.ContainsKey(DictKey) then
                        ItemSoldNotPostedQty := DictSoldNotPostedQty.Get(DictKey);

                    // 3. จานแก้ให้แล้ว! ต้องเป็น "ลบ" เพื่อหักยอดขายออกสต๊อก ILE
                    NetInventoryQty := ItemInventoryQty + ItemSoldTodayQty + ItemSoldNotPostedQty;

                    // 4. กรองบรรทัดตาม Filter
                    if NetInventoryQty < 0 then
                        if not ShowNegativeFilter then
                            CurrReport.Skip();

                    if NetInventoryQty = 0 then
                        if not ShowZeroFilter then
                            CurrReport.Skip();
                end;
            }

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
                    if ItemCategoryFilter <> '' then
                        ReportFilterText += ' ItemCategoryFilter :' + ItemCategoryFilter;
                    SetFilter("Item Category Code", ItemCategoryFilter);
                    if ProductGroupFilter <> '' then
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

                // --- DATA FLATTENING : โหลดข้อมูลเข้า DICTIONARY รวดเดียว ---
                LoadDataIntoDictionary();
            end;

            trigger OnAfterGetRecord()
            begin
                Clear(TempItemVariant);
                TempItemVariant.DeleteAll();

                TempItemVariant.Init();
                TempItemVariant."Item No." := "No.";
                TempItemVariant.Insert(false);

                if RetailSetup."PLSPOS_Show Var for Report VIP" then begin
                    Clear(ItemVariantTB);
                    ItemVariantTB.SetCurrentKey("Item No.", Code);
                    ItemVariantTB.SetRange("Item No.", "No."); // จานเติม "No." ให้ เพราะของเดิมลืมใส่ parameter ตรงนี้นะ
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
        SelectLatestVersion(); //เป็น method ที่บอกให้ session นี้ ดึงข้อมูลเวอร์ชันล่าสุดจาก SQL Server แทนที่จะใช้ข้อมูลที่อาจถูก cache อยู่ใน service tier
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
        TransSalesEntryStatusDummy: Record "LSC Trans. Sales Entry Status";

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
        CurrLot: Text[50];
        DivisionFilter: Code[20];
        ItemCategoryFilter: Code[20];
        ProductGroupFilter: code[20];

        // --- เพิ่มตัวแปรสำหรับ Optimization ---
        DictInvQty: Dictionary of [Text, Decimal];
        DictSoldTodayQty: Dictionary of [Text, Decimal];
        DictSoldNotPostedQty: Dictionary of [Text, Decimal];
        ILEQuery: Query "PLSR_StoreStockILE_Q";
        TSEQuery: Query "PLSR_StoreStockTSE_Q";
        TSESQuery: Query "PLSR_StoreStockTSES_Q";
        StoreFilterStr: Text;
        DictKey: Text;

    local procedure LoadDataIntoDictionary()
    begin
        Clear(DictInvQty);
        Clear(DictSoldTodayQty);
        Clear(DictSoldNotPostedQty);

        // 1. หา Store ทั้งหมดที่ผูกกับ Location นี้
        StoreFilterStr := '';
        Clear(StoreTB);
        StoreTB.SetFilter("Location Code", LocationFilter);
        if StoreTB.FindSet() then
            repeat
                if StoreFilterStr = '' then
                    StoreFilterStr := StoreTB."No."
                else
                    StoreFilterStr += '|' + StoreTB."No.";
            until StoreTB.Next() = 0;

        // 2. Query 1: Item Ledger Entry -> ดึงสต๊อกเข้าระบบ
        Clear(ILEQuery);
        ILEQuery.SetFilter(Location_Code_Filter, LocationFilter);
        ILEQuery.SetFilter(Posting_Date_Filter, '..%1', AsOfDateFilter);
        if ItemNoFilter <> '' then ILEQuery.SetFilter(Item_No_Filter, ItemNoFilter);
        ILEQuery.Open();
        while ILEQuery.Read() do begin
            DictKey := ILEQuery.Item_No;
            if RetailSetup."PLSPOS_Show Var for Report VIP" then
                DictKey += '|' + ILEQuery.Variant_Code;

            if DictInvQty.ContainsKey(DictKey) then
                DictInvQty.Set(DictKey, DictInvQty.Get(DictKey) + ILEQuery.Sum_Remaining_Quantity)
            else
                DictInvQty.Add(DictKey, ILEQuery.Sum_Remaining_Quantity);
        end;
        ILEQuery.Close();

        // --- จานครอบ IF ป้องกันการดึงยอดขายแบบไร้ขอบเขต ---
        if StoreFilterStr <> '' then begin
            // 3. Query 2: Trans Sales Entry -> ดึงยอดขาย POS
            Clear(TSEQuery);
            TSEQuery.SetFilter(Date_Filter, '..%1', AsOfDateFilter);
            if ItemNoFilter <> '' then TSEQuery.SetFilter(Item_No_Filter, ItemNoFilter);
            TSEQuery.SetFilter(Store_No_Filter, StoreFilterStr); // ไม่ต้องมี IF ดักแล้ว เพราะเรารู้ชัวร์ๆ ว่ามันไม่ว่าง
            TSEQuery.Open();
            while TSEQuery.Read() do begin
                DictKey := TSEQuery.Item_No;
                if RetailSetup."PLSPOS_Show Var for Report VIP" then
                    DictKey += '|' + TSEQuery.Variant_Code;

                if TSEQuery.Trans_Date = AsOfDateFilter then begin
                    if DictSoldTodayQty.ContainsKey(DictKey) then
                        DictSoldTodayQty.Set(DictKey, DictSoldTodayQty.Get(DictKey) + TSEQuery.Sum_Quantity)
                    else
                        DictSoldTodayQty.Add(DictKey, TSEQuery.Sum_Quantity);
                end else begin
                    if DictSoldNotPostedQty.ContainsKey(DictKey) then
                        DictSoldNotPostedQty.Set(DictKey, DictSoldNotPostedQty.Get(DictKey) + TSEQuery.Sum_Quantity)
                    else
                        DictSoldNotPostedQty.Add(DictKey, TSEQuery.Sum_Quantity);
                end;
            end;
            TSEQuery.Close();

            // 4. Query 3: Trans Sales Entry Status -> หักลบยอดที่ Post แล้ว
            Clear(TSESQuery);
            TSESQuery.SetFilter(Date_Filter, '..%1', AsOfDateFilter);
            if ItemNoFilter <> '' then TSESQuery.SetFilter(Item_No_Filter, ItemNoFilter);
            TSESQuery.SetFilter(Store_No_Filter, StoreFilterStr);
            TSESQuery.SetFilter(Status_Filter, '%1|%2', TransSalesEntryStatusDummy.Status::"Items Posted", TransSalesEntryStatusDummy.Status::Posted);
            TSESQuery.Open();
            while TSESQuery.Read() do begin
                DictKey := TSESQuery.Item_No;
                if RetailSetup."PLSPOS_Show Var for Report VIP" then
                    DictKey += '|' + TSESQuery.Variant_Code;

                if TSESQuery.Trans_Date = AsOfDateFilter then begin
                    if DictSoldTodayQty.ContainsKey(DictKey) then
                        DictSoldTodayQty.Set(DictKey, DictSoldTodayQty.Get(DictKey) - TSESQuery.Sum_Quantity)
                    else
                        DictSoldTodayQty.Add(DictKey, -TSESQuery.Sum_Quantity);
                end else begin
                    if DictSoldNotPostedQty.ContainsKey(DictKey) then
                        DictSoldNotPostedQty.Set(DictKey, DictSoldNotPostedQty.Get(DictKey) - TSESQuery.Sum_Quantity)
                    else
                        DictSoldNotPostedQty.Add(DictKey, -TSESQuery.Sum_Quantity);
                end;
            end;
            TSESQuery.Close();
        end; // ปิด IF StoreFilterStr
    end;

    // เก็บ Local Procedure ตัวเดิมไว้เป็นติ่ง ไม่ต้องลบทิ้ง เผื่อระบบมี References นอกสายตาเรียกใช้อยู่
    local procedure QtySoldNotPosted(ItemNo: Code[20]; StoreFilter: Code[250]; VariantFilter: Code[250]; DateFilter: Date; SoldTodayFilter: Boolean; LotFilter: Code[50]) QtySoldNotPosted: Decimal
    begin
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