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
            end;

            trigger OnAfterGetRecord()
            begin
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