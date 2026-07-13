report 50107 "PLSR_Sales Report By ItemCate2"
{
    Caption = 'POS Sales Report By Item Category';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50107_POSSalesReportByItemCate.rdl';
    PreviewMode = PrintLayout;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(TransSale; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            // ==========================================
            // 1. คอลัมน์ระดับรายการข้อมูลดิบ (Detail Rows)
            // ==========================================
            column(Variant_Code; TempTB."Variant Code") { }
            column(Name_ComInfo; ComInfo.Name) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(PeriodDate; PeriodDate) { }
            column(ReportFilterText; ReportFilterText) { }
            column(Store_No_TransSale; TempTB."Store No.") { }
            column(Item_Category_Code_TransSale; TempTB."Item Category Code") { }
            column(Item_Category_TransSale; Item_Category) { }
            column(Receipt_No_TransSale; TempTB."Receipt No.") { }
            column(Date_TransSale; Format(TempTB.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(TransType; TempTB."Posting Exception Key") { }
            column(Item_No_TransSale; TempTB."Item No.") { }
            column(Item_Name_ItemTB; ItemName) { }
            column(Unit_of_Measure_TransSale; TempTB."Unit of Measure") { }
            column(Qty; TempTB.Quantity) { }
            column(BaseQty; TempTB."UOM Quantity") { }
            column(UnitPrice; TempTB.Price) { }
            column(Amount; TempTB.Price * TempTB.Quantity) { }
            column(Discount_Amount_TransSale; TempTB."Discount Amount") { }
            column(TotalAmt; TempTB."Net Amount") { }
            column(ShowVariant; not RettailSetup."PLSPOS_Show Var for Report VIP") { }
            // ==========================================
            // 2. คอลัมน์รวมระดับกลุ่มสินค้า (Item_No_TransSale)
            // ==========================================
            column(ItemTotal_Qty; ItemTotal_Qty) { }
            column(ItemTotal_BaseQty; ItemTotal_BaseQty) { }
            column(ItemTotal_Discount; ItemTotal_Discount) { }
            column(ItemTotal_Amount; ItemTotal_Amount) { }
            column(ItemTotal_TotalAmount; ItemTotal_TotalAmount) { }
            // ==========================================
            // 3. คอลัมน์รวมระดับกลุ่มประเภทสินค้าและร้าน (Item_Category_Code_TransSale)
            // ==========================================
            column(ItemCateTotal_Qty; ItemCateTotal_Qty) { }
            column(ItemCateTotal_Discount; ItemCateTotal_Discount) { }
            column(ItemCateTotal_Amount; ItemCateTotal_Amount) { }
            column(ItemCateTotal_TotalAmount; ItemCateTotal_TotalAmount) { }
            // ==========================================
            // 4. คอลัมน์ยอดรวมสุทธิท้ายรายงาน (Grand Totals)
            // ==========================================
            column(GrandTotal_Qty; GrandTotal_Qty) { }
            column(GrandTotal_Discount; GrandTotal_Discount) { }
            column(GrandTotal_Amount; GrandTotal_Amount) { }
            column(GrandTotal_TotalAmount; GrandTotal_TotalAmount) { }
            trigger OnPreDataItem()
            var
                ItemKey: Text;
                CateKey: Text;
                CalcAmount: Decimal;
                Qty: Decimal;
                BaseQty: Decimal;
                UnitPrice: Decimal;
            begin

                IF Choose1Filter THEN BEGIN
                    DateFilterText := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                END
                ELSE
                    IF Choose2Filter THEN BEGIN
                        DateFilterText := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    END;

                IF (StoreFilter <> '') THEN
                    ReportFilterText += 'Store No : ' + FORMAT(StoreFilter + ' ');
                IF (ItemNoFilter <> '') THEN
                    ReportFilterText += ' Item No: ' + FORMAT(ItemNoFilter + ' ');
                IF (ItemCatFilter <> '') THEN
                    ReportFilterText += ' Item Category Code : ' + FORMAT(ItemCatFilter + ' ');

                RettailSetup.Get();

                TempTB.Reset();
                TempTB.DeleteAll();
                Clear(ItemName);
                Clear(DictItemQty);
                Clear(DictItemBaseQty);
                Clear(DictItemAmt);
                Clear(DictItemDisc);
                Clear(DictItemTotalAmt);
                Clear(DictCateTotalAmt);
                Clear(DictCateQty);
                Clear(DictCateAmt);
                Clear(DictCateDisc);
                Clear(DictCateName);
                Clear(DictItemName);
                Clear(ItemName);
                Clear(TransType);

                GrandTotal_Qty := 0;
                GrandTotal_Amount := 0;
                GrandTotal_Discount := 0;
                GrandTotal_TotalAmount := 0;

                if DateFilterText <> '' then
                    SalesQuery.SetFilter(DateFilter, DateFilterText);
                if StoreFilter <> '' then
                    SalesQuery.SetFilter(StoreNoFilter, StoreFilter);
                if ItemNoFilter <> '' then
                    SalesQuery.SetFilter(ItemNoFilter, ItemNoFilter);
                if ItemCatFilter <> '' then
                    SalesQuery.SetFilter(ItemCategoryFilter, ItemCatFilter);


                SalesQuery.Open();

                while SalesQuery.Read() do begin

                    ItemKey := SalesQuery.Item_Category_Code + '_' + SalesQuery.Store_No + '_' + SalesQuery.Item_No;
                    CateKey := SalesQuery.Item_Category_Code + '_' + SalesQuery.Store_No;

                    TransType := Format(SalesQuery.Transaction_Type);
                    if SalesQuery.Return_No_Sale then
                        TransType := 'Refund';

                    if SalesQuery.UOM_Quantity <> 0 then
                        Qty := -SalesQuery.UOM_Quantity
                    else
                        Qty := -SalesQuery.Quantity;

                    BaseQty := -SalesQuery.Quantity;

                    if SalesQuery.UOM_Price <> 0 then
                        UnitPrice := SalesQuery.UOM_Price
                    else
                        UnitPrice := SalesQuery.Price;

                    CalcAmount := (UnitPrice * Qty) - SalesQuery.Discount_Amount;

                    if not DictItemName.ContainsKey(SalesQuery.Item_No) then
                        DictItemName.Add(SalesQuery.Item_No, SalesQuery.Item_Description + ' ' + SalesQuery.Item_Description_2);
                    if not DictCateName.ContainsKey(SalesQuery.Item_Category_Code) then
                        DictCateName.Add(SalesQuery.Item_Category_Code, SalesQuery.Item_Category_Code + ' - ' + SalesQuery.Category_Description);

                    if DictItemQty.ContainsKey(ItemKey) then begin
                        DictItemQty.Set(ItemKey, DictItemQty.Get(ItemKey) + Qty);
                        DictItemBaseQty.Set(ItemKey, DictItemBaseQty.Get(ItemKey) + BaseQty);
                        DictItemAmt.Set(ItemKey, DictItemAmt.Get(ItemKey) + (UnitPrice * Qty));
                        DictItemDisc.Set(ItemKey, DictItemDisc.Get(ItemKey) + SalesQuery.Discount_Amount);
                        DictItemTotalAmt.Set(ItemKey, DictItemTotalAmt.Get(ItemKey) + (UnitPrice * Qty) - SalesQuery.Discount_Amount);
                    end else begin
                        DictItemQty.Add(ItemKey, Qty);
                        DictItemBaseQty.Add(ItemKey, BaseQty);
                        DictItemAmt.Add(ItemKey, (UnitPrice * Qty));
                        DictItemDisc.Add(ItemKey, SalesQuery.Discount_Amount);
                        DictItemTotalAmt.Add(ItemKey, (UnitPrice * Qty) - SalesQuery.Discount_Amount);
                    end;

                    if DictCateQty.ContainsKey(CateKey) then begin
                        DictCateQty.Set(CateKey, DictCateQty.Get(CateKey) + Qty);
                        DictCateDisc.Set(CateKey, DictCateDisc.Get(CateKey) + SalesQuery.Discount_Amount);
                        DictCateAmt.Set(CateKey, DictCateAmt.Get(CateKey) + (UnitPrice * Qty));
                        DictCateTotalAmt.Set(CateKey, DictCateTotalAmt.Get(CateKey) + (UnitPrice * Qty) - SalesQuery.Discount_Amount);
                    end else begin
                        DictCateQty.Add(CateKey, Qty);
                        DictCateDisc.Add(CateKey, SalesQuery.Discount_Amount);
                        DictCateAmt.Add(CateKey, (UnitPrice * Qty));
                        DictCateTotalAmt.Add(CateKey, (UnitPrice * Qty) - SalesQuery.Discount_Amount);
                    end;

                    GrandTotal_Qty += Qty;
                    GrandTotal_Amount += (UnitPrice * Qty);
                    GrandTotal_Discount += SalesQuery.Discount_Amount;
                    GrandTotal_TotalAmount += ((UnitPrice * Qty) - SalesQuery.Discount_Amount);

                    TempTB.Init();
                    TempTB."Store No." := SalesQuery.Store_No;
                    TempTB."Item Category Code" := SalesQuery.Item_Category_Code;
                    TempTB."POS Terminal No." := SalesQuery.POS_Terminal_No;
                    TempTB."Transaction No." := SalesQuery.Transaction_No;
                    TempTB."Line No." := SalesQuery.Line_No;
                    TempTB."Variant Code" := SalesQuery.Variant_Code;
                    TempTB."Posting Exception Key" := TransType;
                    TempTB."Receipt No." := SalesQuery.Receipt_No;
                    TempTB.Date := SalesQuery.Date;
                    TempTB."Item No." := SalesQuery.Item_No;
                    TempTB.Quantity := Qty;
                    TempTB.Price := UnitPrice;
                    TempTB."Discount Amount" := SalesQuery.Discount_Amount;
                    TempTB."Unit of Measure" := SalesQuery.Unit_of_Measure;
                    TempTB."UOM Quantity" := BaseQty;
                    TempTB."Net Amount" := CalcAmount;
                    TempTB.Insert();
                end;
                SalesQuery.Close();
                TempTB.SetCurrentKey("Store No.", "Item Category Code", "Item No.", Date);
                if TempTB.IsEmpty() then
                    CurrReport.Break();
                TransSale.SetRange(Number, 1, TempTB.Count());
            end;

            trigger OnAfterGetRecord()
            var
                ItemKey: Text;
                CateKey: Text;
            begin
                if Number = 1 then begin
                    if not TempTB.FindSet() then
                        CurrReport.Break();
                end else begin
                    if TempTB.Next() = 0 then
                        CurrReport.Break();
                end;
                ItemKey := TempTB."Item Category Code" + '_' + TempTB."Store No." + '_' + TempTB."Item No.";
                CateKey := TempTB."Item Category Code" + '_' + TempTB."Store No.";

                if DictItemQty.ContainsKey(ItemKey) then begin
                    ItemTotal_Qty := DictItemQty.Get(ItemKey);
                    ItemTotal_BaseQty := DictItemBaseQty.Get(ItemKey);
                    ItemTotal_Amount := DictItemAmt.Get(ItemKey);
                    ItemTotal_Discount := DictItemDisc.Get(ItemKey);
                    ItemTotal_TotalAmount := DictItemTotalAmt.Get(ItemKey);
                end;

                if DictCateQty.ContainsKey(CateKey) then begin
                    ItemCateTotal_Qty := DictCateQty.Get(CateKey);
                    ItemCateTotal_Discount := DictCateDisc.Get(CateKey);
                    ItemCateTotal_Amount := DictCateAmt.Get(CateKey);
                    ItemCateTotal_TotalAmount := DictCateTotalAmt.Get(CateKey);
                end;

                if DictItemName.ContainsKey(TempTB."Item No.") then
                    ItemName := DictItemName.Get(TempTB."Item No.")
                else
                    ItemName := '';
                if DictCateName.ContainsKey(TempTB."Item Category Code") then
                    Item_Category := DictCateName.Get(TempTB."Item Category Code")
                else
                    Item_Category := '';
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
                        field("Item No. :"; ItemNoFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = Item."No.";
                            Caption = 'Item No. :';
                        }
                        field("Item Category Code :"; ItemCatFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = "Item Category".Code;
                            Caption = 'Item Category Code :';
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
            FDateFilter := Today;
            Choose1Filter := false;
            Choose2Filter := true;
        end;
    }

    trigger OnPreReport()
    begin
        ComInfo.Get();
        ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
    end;

    var
        SalesQuery: Query "PLSR_SalesReportByItemCateQ";
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        RettailSetup: Record "LSC Retail Setup";
        TempTB: Record "LSC Trans. Sales Entry" temporary;
        ShowTime: Text[50];
        ShowDate: Text[50];
        TransType: Text[50];
        ReportFilterText: Text[250];
        Item_Category: Text[120];
        ItemName: Text[150];

        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        ItemCatFilter: Code[20];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        DateFilterText: Text[100];
        PeriodDate: Text[150];

        DictItemQty: Dictionary of [Text, Decimal];
        DictItemBaseQty: Dictionary of [Text, Decimal];
        DictItemDisc: Dictionary of [Text, Decimal];
        DictItemAmt: Dictionary of [Text, Decimal];
        DictItemTotalAmt: Dictionary of [Text, Decimal];
        DictCateQty: Dictionary of [Text, Decimal];
        DictCateDisc: Dictionary of [Text, Decimal];
        DictCateAmt: Dictionary of [Text, Decimal];
        DictCateTotalAmt: Dictionary of [Text, Decimal];
        DictCateName: Dictionary of [Code[20], Text[150]];
        DictItemName: Dictionary of [Code[20], Text[150]];

        ItemTotal_Qty: Decimal;
        ItemTotal_BaseQty: Decimal;
        ItemTotal_Discount: Decimal;
        ItemTotal_Amount: Decimal;
        ItemTotal_TotalAmount: Decimal;
        ItemCateTotal_Qty: Decimal;
        ItemCateTotal_Discount: Decimal;
        ItemCateTotal_Amount: Decimal;
        ItemCateTotal_TotalAmount: Decimal;
        GrandTotal_Qty: Decimal;
        GrandTotal_Discount: Decimal;
        GrandTotal_Amount: Decimal;
        GrandTotal_TotalAmount: Decimal;
}