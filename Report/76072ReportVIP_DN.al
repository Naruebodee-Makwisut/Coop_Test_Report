report 50101 "Sales Report By ProdGroup"
{
    Caption = 'POS Sales Report By Product Group_Test';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50101DN_POSSalesReportByProdGroup.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        // dataitem(TransSaleFilter; "LSC Trans. Sales Entry")
        // {
        //     RequestFilterFields = "Store No.", "Item No.", "Retail Product Code";
        //     trigger OnPreDataItem()
        //     begin
        //         CurrReport.Break();
        //     end;
        // }

        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter('1..'));

            column(Variant_Code; TmpTransSaleEntry."Variant Code") { }
            column(Name_ComInfo; ComInfo.Name) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(PeriodDate; PeriodDate) { }
            column(ReportFilterText; ReportFilterText) { }
            column(Store_No_TransSale; TmpTransSaleEntry."Store No.") { }
            column(Retail_Product_Code_TransSale; TmpTransSaleEntry."Retail Product Code") { }
            column(Retail_Product_TransSale; GetProdDisplay()) { }
            column(Receipt_No_TransSale; TmpTransSaleEntry."Receipt No.") { }
            column(Date_TransSale; GetDateDisplay()) { }
            column(TransType; GetTransType()) { }
            column(Item_No_TransSale; TmpTransSaleEntry."Item No.") { }
            column(Item_Name_ItemTB; GetItemFullName()) { }
            column(Unit_of_Measure_TransSale; TmpTransSaleEntry."Unit of Measure") { }
            column(Qty; GetQty()) { }
            column(BaseQty; -TmpTransSaleEntry.Quantity) { }
            column(UnitPrice; GetUnitPrice()) { }
            column(Amount; GetAmount()) { }
            column(Discount_Amount_TransSale; TmpTransSaleEntry."Discount Amount") { }
            column(TotalAmt; GetTotalAmt()) { }
            column(ShowVariant; GetShowVariant()) { }

            // ---- Item level totals ----
            column(ItemTotalQty; GetDecimalSafe(TmpItemQty, TmpTransSaleEntry."Store No." + '_' + TmpTransSaleEntry."Retail Product Code" + '_' + TmpTransSaleEntry."Item No."))
            { }
            column(ItemTotalAmount; GetDecimalSafe(TmpItemAmount, TmpTransSaleEntry."Store No." + '_' + TmpTransSaleEntry."Retail Product Code" + '_' + TmpTransSaleEntry."Item No."))
            { }
            column(ItemTotalDiscount; GetDecimalSafe(TmpItemDiscount, TmpTransSaleEntry."Store No." + '_' + TmpTransSaleEntry."Retail Product Code" + '_' + TmpTransSaleEntry."Item No."))
            { }
            column(ItemTotalAmt; GetDecimalSafe(TmpItemTotalAmt, TmpTransSaleEntry."Store No." + '_' + TmpTransSaleEntry."Retail Product Code" + '_' + TmpTransSaleEntry."Item No."))
            { }

            // ---- Product Group level totals ----
            column(ProductTotalQty; GetDecimalSafe(TmpProductQty, TmpTransSaleEntry."Store No." + '_' + TmpTransSaleEntry."Retail Product Code"))
            { }
            column(ProductTotalAmount; GetDecimalSafe(TmpProductAmount, TmpTransSaleEntry."Store No." + '_' + TmpTransSaleEntry."Retail Product Code"))
            { }
            column(ProductTotalDiscount; GetDecimalSafe(TmpProductDiscount, TmpTransSaleEntry."Store No." + '_' + TmpTransSaleEntry."Retail Product Code"))
            { }
            column(ProductTotalAmt; GetDecimalSafe(TmpProductTotalAmt, TmpTransSaleEntry."Store No." + '_' + TmpTransSaleEntry."Retail Product Code"))
            { }

            // ---- Grand Total ----
            column(GrandTotalQty; GrandQty)
            { }
            column(GrandTotalAmount; GrandAmount)
            { }
            column(GrandTotalDiscount; GrandDiscount)
            { }
            column(GrandTotalAmt; GrandTotalAmt)
            { }

            trigger OnPreDataItem()
            var
                LoopQty: Decimal;
                LoopUnitPrice: Decimal;
                LoopAmount: Decimal;
                LoopDiscount: Decimal;
                LoopTotalAmt: Decimal;
            begin
                if Choose1Filter then begin
                    QuerySalesProdGroup.SetFilter(DateFilter, '%1..%2', FromDateFilter, TodateFilter);
                    PeriodDate := 'ประจำงวดวันที่ ' + Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') +
                                  ' ถึง ' + Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                end else
                    if Choose2Filter then begin
                        QuerySalesProdGroup.SetFilter(DateFilter, '%1', FDateFilter);
                        PeriodDate := 'ประจำงวดวันที่ ' + Format(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    end;

                if StoreFilter <> '' then begin
                    QuerySalesProdGroup.SetFilter(StoreNoFilter, StoreFilter);
                    ReportFilterText += 'Store No : ' + StoreFilter + ' ';
                end;
                if ItemNoFilter <> '' then begin
                    QuerySalesProdGroup.SetFilter(ItemNoFilter, ItemNoFilter);
                    ReportFilterText += ' Item No: ' + ItemNoFilter + ' ';
                end;
                if ProductGroupFilter <> '' then begin
                    QuerySalesProdGroup.SetFilter(ProductGroupFilter, ProductGroupFilter);
                    ReportFilterText += ' Product Group Code : ' + ProductGroupFilter + ' ';
                end;

                RettailSetup.Get();

                TmpTransSaleEntry.Reset();
                TmpTransSaleEntry.DeleteAll();
                Clear(TmpItemFullName);
                Clear(TmpProdGroupDesc);
                RowSeq := 0;

                // ---- โหลดข้อมูลลง Temp Table รอบเดียว ไม่ต้องสร้าง sort key เอง ----
                if QuerySalesProdGroup.Open() then begin
                    while QuerySalesProdGroup.Read() do begin
                        RowSeq += 1;

                        TmpTransSaleEntry.Init();
                        TmpTransSaleEntry."Store No." := QuerySalesProdGroup.Store_No_;
                        TmpTransSaleEntry."Item No." := QuerySalesProdGroup.Item_No_;
                        TmpTransSaleEntry."Retail Product Code" := QuerySalesProdGroup.Retail_Product_Code;
                        TmpTransSaleEntry."Variant Code" := QuerySalesProdGroup.Variant_Code;
                        TmpTransSaleEntry.Quantity := QuerySalesProdGroup.Quantity;
                        TmpTransSaleEntry."UOM Quantity" := QuerySalesProdGroup.UOM_Quantity;
                        TmpTransSaleEntry.Price := QuerySalesProdGroup.Price;
                        TmpTransSaleEntry."UOM Price" := QuerySalesProdGroup.UOM_Price;
                        TmpTransSaleEntry."Unit of Measure" := QuerySalesProdGroup.Unit_of_Measure;
                        TmpTransSaleEntry."Discount Amount" := QuerySalesProdGroup.Discount_Amount;
                        TmpTransSaleEntry.Date := QuerySalesProdGroup.Date_;
                        TmpTransSaleEntry."Receipt No." := QuerySalesProdGroup.Receipt_No_;
                        TmpTransSaleEntry."Return No Sale" := QuerySalesProdGroup.Return_No_Sale;
                        TmpTransSaleEntry."POS Line Description" := Format(QuerySalesProdGroup.Transaction_Type);
                        TmpTransSaleEntry."Line No." := RowSeq;
                        TmpTransSaleEntry.Insert();

                        TmpItemFullName.Add(RowSeq, QuerySalesProdGroup.Item_Description + ' ' + QuerySalesProdGroup.Item_Description2);
                        TmpProdGroupDesc.Add(RowSeq, QuerySalesProdGroup.ProdGroup_Description);

                        // ---- คำนวณค่าของแถวนี้ (logic เดียวกับ Helper Function ที่ใช้ตอนแสดงผล) ----
                        if QuerySalesProdGroup.UOM_Quantity <> 0 then
                            LoopQty := -QuerySalesProdGroup.UOM_Quantity
                        else
                            LoopQty := -QuerySalesProdGroup.Quantity;

                        if QuerySalesProdGroup.UOM_Price <> 0 then
                            LoopUnitPrice := QuerySalesProdGroup.UOM_Price
                        else
                            LoopUnitPrice := QuerySalesProdGroup.Price;

                        LoopAmount := LoopUnitPrice * LoopQty;
                        LoopDiscount := QuerySalesProdGroup.Discount_Amount;
                        LoopTotalAmt := LoopAmount - LoopDiscount;

                        // ---- สะสมยอดระดับ Item (Store+Product+Item) ----
                        ItemKey := QuerySalesProdGroup.Store_No_ + '_' + QuerySalesProdGroup.Retail_Product_Code + '_' + QuerySalesProdGroup.Item_No_;
                        AddToDecimalDict(TmpItemQty, ItemKey, LoopQty);
                        AddToDecimalDict(TmpItemAmount, ItemKey, LoopAmount);
                        AddToDecimalDict(TmpItemDiscount, ItemKey, LoopDiscount);
                        AddToDecimalDict(TmpItemTotalAmt, ItemKey, LoopTotalAmt);

                        // ---- สะสมยอดระดับ Product Group (Store+Product) ----
                        ProductKey := QuerySalesProdGroup.Store_No_ + '_' + QuerySalesProdGroup.Retail_Product_Code;
                        AddToDecimalDict(TmpProductQty, ProductKey, LoopQty);
                        AddToDecimalDict(TmpProductAmount, ProductKey, LoopAmount);
                        AddToDecimalDict(TmpProductDiscount, ProductKey, LoopDiscount);
                        AddToDecimalDict(TmpProductTotalAmt, ProductKey, LoopTotalAmt);

                        // ---- สะสม Grand Total ----
                        GrandQty += LoopQty;
                        GrandAmount += LoopAmount;
                        GrandDiscount += LoopDiscount;
                        GrandTotalAmt += LoopTotalAmt;
                    end;
                    QuerySalesProdGroup.Close();
                end;

                // ---- ตั้ง Key ตามลำดับ Group ที่ต้องการ แล้วให้ Table Manager sort ให้เอง (native, เร็วกว่า sort เองเยอะ) ----
                TmpTransSaleEntry.Reset();
                TmpTransSaleEntry.SetCurrentKey("Store No.", "Retail Product Code", "Item No.", "Line No.");

                if not TmpTransSaleEntry.FindSet() then
                    CurrReport.Break();
            end;

            trigger OnAfterGetRecord()
            begin
                if Number > 1 then
                    if TmpTransSaleEntry.Next() = 0 then
                        CurrReport.Break();

                RowSeq := TmpTransSaleEntry."Line No.";  // ใช้ดึงค่าจาก Dictionary เท่านั้น
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
                        field("Product Group Code :"; ProductGroupFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = "LSC Retail Product Group".Code;
                            Caption = 'Product Group Code :';
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
        ShowDate := Format(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
    end;

    var
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        RettailSetup: Record "LSC Retail Setup";
        QuerySalesProdGroup: Query "PLSR Sales By Prod Query";

        TmpTransSaleEntry: Record "LSC Trans. Sales Entry" temporary;
        TmpItemFullName: Dictionary of [Integer, Text];
        TmpProdGroupDesc: Dictionary of [Integer, Text];
        TmpQtyTotal: Dictionary of [Text, Decimal];
        RowSeq: Integer;

        ShowTime: Text[50];
        ShowDate: Text[50];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        RetailProKey: Text;
        ItemNoKey: Text;
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        ProductGroupFilter: Code[20];

        // ---- เพิ่มส่วนสะสมยอด: ระดับ Item (Store+Product+Item) ----
        TmpItemQty: Dictionary of [Text, Decimal];
        TmpItemAmount: Dictionary of [Text, Decimal];
        TmpItemDiscount: Dictionary of [Text, Decimal];
        TmpItemTotalAmt: Dictionary of [Text, Decimal];

        // ---- ระดับ Product Group (Store+Product) ----
        TmpProductQty: Dictionary of [Text, Decimal];
        TmpProductAmount: Dictionary of [Text, Decimal];
        TmpProductDiscount: Dictionary of [Text, Decimal];
        TmpProductTotalAmt: Dictionary of [Text, Decimal];

        // ---- Grand Total ทั้งรายงาน ----
        GrandQty: Decimal;
        GrandAmount: Decimal;
        GrandDiscount: Decimal;
        GrandTotalAmt: Decimal;

        ItemKey: Text;
        ProductKey: Text;

    local procedure GetQty(): Decimal
    begin
        if TmpTransSaleEntry."UOM Quantity" <> 0 then
            exit(-TmpTransSaleEntry."UOM Quantity");
        exit(-TmpTransSaleEntry.Quantity);
    end;

    local procedure GetUnitPrice(): Decimal
    begin
        if TmpTransSaleEntry."UOM Price" <> 0 then
            exit(TmpTransSaleEntry."UOM Price");
        exit(TmpTransSaleEntry.Price);
    end;

    local procedure GetAmount(): Decimal
    begin
        exit(GetUnitPrice() * GetQty());
    end;

    local procedure GetTotalAmt(): Decimal
    begin
        exit(GetAmount() - TmpTransSaleEntry."Discount Amount");
    end;

    local procedure GetTransType(): Text[50]
    begin
        if TmpTransSaleEntry."Return No Sale" then
            exit('Refund');
        exit(TmpTransSaleEntry."POS Line Description");
    end;

    local procedure GetDateDisplay(): Text[20]
    begin
        exit(Format(TmpTransSaleEntry.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>'));
    end;

    local procedure GetProdDisplay(): Text[200]
    begin
        exit(TmpTransSaleEntry."Retail Product Code" + ' - ' + TmpProdGroupDesc.Get(RowSeq));
    end;

    local procedure GetItemFullName(): Text[200]
    begin
        exit(TmpItemFullName.Get(RowSeq));
    end;

    local procedure GetShowVariant(): Boolean
    begin
        exit(not RettailSetup."PLSPOS_Show Var for Report VIP");
    end;

    local procedure AddToDecimalDict(var TargetDict: Dictionary of [Text, Decimal]; DictKey: Text; AddValue: Decimal)
    begin
        if TargetDict.ContainsKey(DictKey) then
            TargetDict.Set(DictKey, TargetDict.Get(DictKey) + AddValue)
        else
            TargetDict.Add(DictKey, AddValue);
    end;

    local procedure GetDecimalSafe(var SourceDict: Dictionary of [Text, Decimal]; DictKey: Text): Decimal
    begin
        if SourceDict.ContainsKey(DictKey) then
            exit(SourceDict.Get(DictKey));
        exit(0);
    end;
}

// report 50101 "Sales Report By ProdGroup"
// {
//     Caption = 'POS Sales Report By Product Group_Test';
//     DefaultLayout = RDLC;
//     RDLCLayout = './ReportLayouts/Rep50101_POSSalesReportByProdGroup.rdl';
//     PreviewMode = PrintLayout;

//     dataset
//     {
//         // dataitem(TransSaleFilter; "LSC Trans. Sales Entry")
//         // {
//         //     RequestFilterFields = "Store No.", "Item No.", "Retail Product Code";
//         //     trigger OnPreDataItem()
//         //     begin
//         //         CurrReport.Break();
//         //     end;
//         // }

//         dataitem(Integer; Integer)
//         {
//             DataItemTableView = sorting(Number) where(Number = filter('1..'));

//             column(Variant_Code; CurrentVariantCode) { }
//             column(Name_ComInfo; ComInfo.Name) { }
//             column(ShowDate; ShowDate) { }
//             column(ShowTime; ShowTime) { }
//             column(PeriodDate; PeriodDate) { }
//             column(ReportFilterText; ReportFilterText) { }
//             column(Store_No_TransSale; CurrentStoreNo) { }
//             column(Retail_Product_Code_TransSale; CurrentProdCode) { }
//             column(Retail_Product_TransSale; CurrentProdDisplay) { }
//             column(Receipt_No_TransSale; CurrentReceiptNo) { }
//             column(Date_TransSale; CurrentDateDisplay) { }
//             column(TransType; CurrentTransType) { }
//             column(Item_No_TransSale; CurrentItemNo) { }
//             column(Item_Name_ItemTB; CurrentItemName) { }
//             column(Unit_of_Measure_TransSale; CurrentUOM) { }
//             column(Qty; CurrentQty) { }
//             column(BaseQty; CurrentBaseQty) { }
//             column(UnitPrice; CurrentUnitPrice) { }
//             column(Amount; CurrentAmount) { }
//             column(Discount_Amount_TransSale; CurrentDiscountAmt) { }
//             column(TotalAmt; CurrentTotalAmt) { }
//             column(ShowVariant; CurrentShowVariant) { }

//             trigger OnPreDataItem()
//             begin
//                 // Date filter
//                 if Choose1Filter then begin
//                     QuerySalesProdGroup.SetFilter(DateFilter, '%1..%2', FromDateFilter, TodateFilter);
//                     PeriodDate := 'ประจำงวดวันที่ ' + Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') +
//                                   ' ถึง ' + Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
//                 end else
//                     if Choose2Filter then begin
//                         QuerySalesProdGroup.SetFilter(DateFilter, '%1', FDateFilter);
//                         PeriodDate := 'ประจำงวดวันที่ ' + Format(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
//                     end;

//                 if StoreFilter <> '' then begin
//                     QuerySalesProdGroup.SetFilter(StoreNoFilter, StoreFilter);
//                     ReportFilterText += 'Store No : ' + StoreFilter + ' ';
//                 end;
//                 if ItemNoFilter <> '' then begin
//                     QuerySalesProdGroup.SetFilter(ItemNoFilter, ItemNoFilter);
//                     ReportFilterText += ' Item No: ' + ItemNoFilter + ' ';
//                 end;
//                 if ProductGroupFilter <> '' then begin
//                     QuerySalesProdGroup.SetFilter(ProductGroupFilter, ProductGroupFilter);
//                     ReportFilterText += ' Product Group Code : ' + ProductGroupFilter + ' ';
//                 end;

//                 // ส่ง filter จากตัวแปรใน requestpage ไปให้ Query โดยตรง
//                 RettailSetup.Get();
//                 QuerySalesProdGroup.Open();
//             end;

//             trigger OnAfterGetRecord()
//             begin
//                 if not QuerySalesProdGroup.Read() then
//                     CurrReport.Break();

//                 // Qty / Price
//                 if QuerySalesProdGroup.UOM_Quantity <> 0 then
//                     CurrentQty := -QuerySalesProdGroup.UOM_Quantity
//                 else
//                     CurrentQty := -QuerySalesProdGroup.Quantity;

//                 if QuerySalesProdGroup.UOM_Price <> 0 then
//                     CurrentUnitPrice := QuerySalesProdGroup.UOM_Price
//                 else
//                     CurrentUnitPrice := QuerySalesProdGroup.Price;

//                 CurrentBaseQty := -QuerySalesProdGroup.Quantity;
//                 CurrentDiscountAmt := QuerySalesProdGroup.Discount_Amount;
//                 CurrentAmount := CurrentUnitPrice * CurrentQty;
//                 CurrentTotalAmt := CurrentAmount - CurrentDiscountAmt;

//                 // TransType
//                 CurrentTransType := Format(QuerySalesProdGroup.Transaction_Type);
//                 if QuerySalesProdGroup.Return_No_Sale then
//                     CurrentTransType := 'Refund';

//                 // Display fields
//                 CurrentDateDisplay := Format(QuerySalesProdGroup.Date_, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
//                 CurrentItemName := QuerySalesProdGroup.Item_Description + ' ' + QuerySalesProdGroup.Item_Description2;
//                 CurrentProdDisplay := QuerySalesProdGroup.Retail_Product_Code + ' - ' + QuerySalesProdGroup.ProdGroup_Description;
//                 CurrentStoreNo := QuerySalesProdGroup.Store_No_;
//                 CurrentProdCode := QuerySalesProdGroup.Retail_Product_Code;
//                 CurrentReceiptNo := QuerySalesProdGroup.Receipt_No_;
//                 CurrentItemNo := QuerySalesProdGroup.Item_No_;
//                 CurrentUOM := QuerySalesProdGroup.Unit_of_Measure;
//                 CurrentVariantCode := QuerySalesProdGroup.Variant_Code;
//                 CurrentShowVariant := not RettailSetup."PLSPOS_Show Var for Report VIP";
//             end;
//         }
//     }

//     requestpage
//     {
//         layout
//         {
//             area(Content)
//             {
//                 group("Filter")
//                 {
//                     group("Data Filter")
//                     {
//                         field("Store No. :"; StoreFilter)
//                         {
//                             ApplicationArea = All;
//                             TableRelation = "LSC Store"."No.";
//                             Caption = 'Store No. :';
//                         }
//                         field("Item No. :"; ItemNoFilter)
//                         {
//                             ApplicationArea = All;
//                             TableRelation = Item."No.";
//                             Caption = 'Item No. :';
//                         }
//                         field("Product Group Code :"; ProductGroupFilter)
//                         {
//                             ApplicationArea = All;
//                             TableRelation = "LSC Retail Product Group".Code;
//                             Caption = 'Product Group Code :';
//                         }
//                     }
//                     group("Date Filter 1")
//                     {
//                         field(Period; Choose1Filter)
//                         {
//                             ApplicationArea = All;
//                             Caption = 'Period';
//                             trigger OnValidate()
//                             begin
//                                 if Choose1Filter then
//                                     Choose2Filter := false
//                                 else
//                                     Choose2Filter := true;
//                             end;
//                         }
//                         group("Period Date")
//                         {
//                             field("Start Date"; FromDateFilter)
//                             {
//                                 ApplicationArea = All;
//                                 Editable = Choose1Filter;
//                                 Caption = 'Start Date';
//                             }
//                             field("End Date"; TodateFilter)
//                             {
//                                 ApplicationArea = All;
//                                 Editable = Choose1Filter;
//                                 Caption = 'End Date';
//                             }
//                         }
//                     }
//                     group("Date Filter 2")
//                     {
//                         field("At Date"; Choose2Filter)
//                         {
//                             ApplicationArea = All;
//                             Caption = 'At Date';
//                             trigger OnValidate()
//                             begin
//                                 if Choose2Filter then
//                                     Choose1Filter := false
//                                 else
//                                     Choose1Filter := true;
//                             end;
//                         }
//                         group("At Date filter")
//                         {
//                             field("Date"; FDateFilter)
//                             {
//                                 ApplicationArea = All;
//                                 Editable = Choose2Filter;
//                                 Caption = 'Date';
//                             }
//                         }
//                     }
//                 }
//             }
//         }

//         trigger OnOpenPage()
//         begin
//             SelectLatestVersion();
//             FDateFilter := Today;
//             Choose1Filter := false;
//             Choose2Filter := true;
//         end;
//     }

//     trigger OnPreReport()
//     begin
//         ComInfo.Get();
//         ShowDate := Format(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
//         ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
//     end;

//     var
//         LSVIPRepFunction: Codeunit "PLSR_Report Function";
//         ComInfo: Record "Company Information";
//         RettailSetup: Record "LSC Retail Setup";
//         QuerySalesProdGroup: Query "PLSR Sales By Prod Query";
//         ShowTime: Text[50];
//         ShowDate: Text[50];
//         PeriodDate: Text[150];
//         ReportFilterText: Text[250];
//         FromDateFilter: Date;
//         TodateFilter: Date;
//         FDateFilter: Date;
//         Choose1Filter: Boolean;
//         Choose2Filter: Boolean;
//         CurrentStoreNo: Code[20];
//         CurrentProdCode: Code[20];
//         CurrentReceiptNo: Code[20];
//         CurrentItemNo: Code[20];
//         CurrentUOM: Code[10];
//         CurrentVariantCode: Code[20];
//         CurrentTransType: Text[50];
//         CurrentDateDisplay: Text[20];
//         CurrentItemName: Text[200];
//         CurrentProdDisplay: Text[200];
//         CurrentQty: Decimal;
//         CurrentBaseQty: Decimal;
//         CurrentUnitPrice: Decimal;
//         CurrentAmount: Decimal;
//         CurrentDiscountAmt: Decimal;
//         CurrentTotalAmt: Decimal;
//         CurrentShowVariant: Boolean;
//         StoreFilter: Code[20];
//         ItemNoFilter: Code[20];
//         ProductGroupFilter: Code[20];
// }