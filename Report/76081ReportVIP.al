report 50105 "Store Stock Checking"
{
    Caption = 'Store Stock Checking';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50105_StoreStockChecking.rdl';
    PreviewMode = PrintLayout;
    // AVPWDLSVIP 26/06/2025 > Improve Performance of VIP Report(76081) น้องอิง
    dataset
    {
        dataitem(ReportHeader; Integer)
        {
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
                ItemTB.Reset();
                // หัวใจสำคัญ: สั่งเรียงลำดับด้วย Key มาตรฐานที่เรายัดค่า Item|Variant ไว้
                ItemTB.SetCurrentKey("Search Description");
                ItemTB.Ascending(true);
                SetRange(Number, 1, ItemTB.Count());
                if ItemTB.IsEmpty() then
                    CurrReport.Break();
            end;

            trigger OnAfterGetRecord()
            begin
                // วนลูปอ่านข้อมูล ซึ่งตอนนี้มันจะออกมาเรียงสวยงามเป๊ะๆ ตาม Item No. และ Variant 
                if Number = 1 then begin
                    if not ItemTB.FindSet() then
                        CurrReport.Break();
                end else begin
                    if ItemTB.Next() = 0 then
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
                        // field("Show Negative :"; ShowNegativeFilter)
                        // {
                        //     ApplicationArea = all;
                        //     Caption = 'Show Negative :';
                        // }
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
        ItemTB: Record "Item" temporary;
        ComInfo: Record "Company Information";
        RetailSetup: Record "LSC Retail Setup";
        AsOfDateFilter: Date;
        LocationFilter, ItemNoFilter, DivisionFilter, ItemCategoryFilter, ProductGroupFilter : Code[20];
        ShowItemBlock, ShowZeroFilter, ShowNegativeFilter : Boolean;
        ShowDate, ShowTime, ReportFilterText, StoreFilterText : Text;

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
        if LocationFilter = '' then
            Error('Please input Location filter!');

        // --- เตรียม Report Filter Text และแปลงรหัส Location เป็น Store ---
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

        // ---  STEP 1: กวาดสินค้ากรณีเปิด Show Zero ---
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
                        FindOrCreateItemTB(ItemRecord."No.", '', ItemTB, EntryNo, ShowVar); // Blank Variant

                        ItemVariant.Reset();
                        ItemVariant.SetRange("Item No.", ItemRecord."No.");
                        if ItemVariant.FindSet() then
                            repeat
                                FindOrCreateItemTB(ItemRecord."No.", ItemVariant.Code, ItemTB, EntryNo, ShowVar);
                            until ItemVariant.Next() = 0;
                    end else begin
                        FindOrCreateItemTB(ItemRecord."No.", '', ItemTB, EntryNo, ShowVar);
                    end;
                until ItemRecord.Next() = 0;
        end;

        // ---  STEP 2: ดึงยอดคงคลังสุทธิ (ILE) ---
        Clear(ILEQuery);
        if ItemNoFilter <> '' then ILEQuery.SetFilter(Item_No, ItemNoFilter);
        if LocationFilter <> '' then ILEQuery.SetFilter(Location_Code, LocationFilter);
        ILEQuery.SetFilter(Posting_Date, '<=%1', AsOfDateFilter);
        if ILEQuery.Open() then begin
            while ILEQuery.Read() do begin
                if FindOrCreateItemTB(ILEQuery.Q_Item_No, ILEQuery.Q_Variant_Code, ItemTB, EntryNo, ShowVar) then begin
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
        if SalesQuery.Open() then begin
            while SalesQuery.Read() do begin
                if FindOrCreateItemTB(SalesQuery.Q_Item_No, SalesQuery.Q_Variant_Code, ItemTB, EntryNo, ShowVar) then begin
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
        if StatusQuery.Open() then begin
            while StatusQuery.Read() do begin
                if FindOrCreateItemTB(StatusQuery.Q_Item_No, StatusQuery.Q_Variant_Code, ItemTB, EntryNo, ShowVar) then begin
                    ItemTB."Unit Cost" -= StatusQuery.Sum_Quantity;
                    ItemTB.Modify();
                end;
            end;
            StatusQuery.Close();
        end;

        // ---  STEP 4: ดึงยอดขายในอดีต ---
        // ทำแบบเดียวกับ Step 3 แต่เปลี่ยน Date_Filter เป็น 0D .. Today - 1 แล้วหยอดยอดเข้า ItemTB."Standard Cost"

        // --- STEP 5: เติม Description และคัดกรองขยะทิ้ง ---
        ItemTB.Reset();
        if ItemTB.FindSet() then
            repeat
                if ItemRecord.Get(ItemTB."No. 2") then begin
                    if (not ShowZeroFilter) and
                       ((ItemRecord.Type <> ItemRecord.Type::Inventory) or
                        ((not ShowItemBlock) and ItemRecord.Blocked) or
                        ((DivisionFilter <> '') and (ItemRecord."LSC Division Code" <> DivisionFilter)) or
                        ((ItemCategoryFilter <> '') and (ItemRecord."Item Category Code" <> ItemCategoryFilter)) or
                        ((ProductGroupFilter <> '') and (ItemRecord."LSC Retail Product Code" <> ProductGroupFilter)))
                    then begin
                        ItemTB.Mark(true);
                    end else begin
                        ItemTB.Description := ItemRecord.Description;
                        ItemTB."Base Unit of Measure" := ItemRecord."Base Unit of Measure";
                        ItemTB."Last Direct Cost" := ItemTB."Unit Price" + ItemTB."Unit Cost" + ItemTB."Standard Cost";
                        ItemTB.Modify();
                    end;
                end else begin
                    ItemTB.Mark(true);
                end;
            until ItemTB.Next() = 0;

        ItemTB.MarkedOnly(true);
        if not ItemTB.IsEmpty() then
            ItemTB.DeleteAll();
        ItemTB.Reset();

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

    // ฟังก์ชันทำหน้าที่ยัดรหัสลง Index เพื่อความไวแสงและเอาไว้ Sort ออกรายงาน
    local procedure FindOrCreateItemTB(ItemNo: Code[20]; VariantCode: Code[20]; var ItemTB: Record Item temporary; var EntryNo: Integer; ShowVar: Boolean): Boolean
    var
        SearchKey: Code[100];
    begin
        if not ShowVar then
            VariantCode := '';

        // แปลงร่าง: เอา Item ต่อด้วย Variant คั่นด้วย | เช่น (1000|V1) เพื่อกันการจัดเรียงเพี้ยน
        SearchKey := CopyStr(ItemNo + '|' + VariantCode, 1, 100);

        ItemTB.Reset();
        // ใช้ Index Key ในการค้นหา ข้อมูลล้านบรรทัดก็หาเจอในเสี้ยววินาที!
        ItemTB.SetCurrentKey("Search Description");
        ItemTB.SetRange("Search Description", SearchKey);
        if ItemTB.FindFirst() then
            exit(true);

        EntryNo += 1;
        ItemTB.Init();
        ItemTB."No." := Format(EntryNo);
        ItemTB."No. 2" := ItemNo;
        ItemTB."Vendor Item No." := VariantCode;
        ItemTB."Search Description" := SearchKey; // เก็บกุญแจไว้
        ItemTB.Insert();
        exit(true);
    end;
    // C-AVPWDLSVIP 29/06/2025 > Improve Performance of VIP Report(76081) น้องอิง
}