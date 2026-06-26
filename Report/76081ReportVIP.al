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
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));

            column(StoreNo_Name_StoreTB; StoreFilterText) { }
            column(ReportFilterText; ReportFilterText) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }

            column(ItemNo; TempStockBuffer."Item No.") { }
            column(Description_Item; TempStockBuffer.Description) { }
            column(BaseUOM_Item; TempStockBuffer."Base Unit of Measure") { }
            column(Variant_Code; TempStockBuffer."Variant Code") { }

            column(ItemInventoryQty; format(TempStockBuffer.ItemInventoryQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ItemSoldNotPostedQty; format(TempStockBuffer.ItemSoldNotPostedQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ItemSoldTodayQty; format(TempStockBuffer.ItemSoldTodayQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(NetInventoryQty; format(TempStockBuffer.NetInventoryQty, 0, '<Sign><Integer Thousand><Decimals>')) { }
            column(ShowVariant; RetailSetup."PLSPOS_Show Var for Report VIP") { }

            trigger OnPreDataItem()
            var
                StoreTB: Record "LSC Store";
            begin
                AsOfDateFilter := Today;

                if LocationFilter = '' then
                    Error('Please input Location filter!');

                Clear(ReportFilterText);
                if (ItemNoFilter <> '') then
                    ReportFilterText += 'Item No. : ' + FORMAT(ItemNoFilter + ' ');

                if (LocationFilter <> '') then
                    ReportFilterText += ' Location : ' + FORMAT(LocationFilter + ' ');

                if DivisionFilter <> '' then begin
                    ReportFilterText += ' Division : ' + DivisionFilter;
                    if ItemCategoryFilter <> '' then
                        ReportFilterText += ' ItemCategoryFilter : ' + ItemCategoryFilter;
                    if ProductGroupFilter <> '' then
                        ReportFilterText += ' ProductGroupFilter : ' + ProductGroupFilter;
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

                //สั่งกวาดข้อมูลลง Temp Table
                BuildTempData();
            end;

            trigger OnAfterGetRecord()
            begin
                // เดินหน้าอ่านข้อมูลจาก Temp Table ทีละบรรทัด
                if Number = 1 then begin
                    TempStockBuffer.SetCurrentKey("Item No.", "Variant Code");
                    if not TempStockBuffer.FindSet() then
                        CurrReport.Break();
                end else begin
                    if TempStockBuffer.Next() = 0 then
                        CurrReport.Break();
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