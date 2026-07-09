report 50106 "PLSR_Sales Report By Division2"
{
    Caption = 'POS Sales Report By Division';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50106_POSSalesReportByDivision.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem(TransSale; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter('1..'));

            // ==========================================
            // 1. คอลัมน์ระดับรายการข้อมูลดิบ (Detail Rows)
            // ==========================================
            column(Name_ComInfo; ComInfo.Name) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(PeriodDate; PeriodDate) { }
            column(ReportFilterText; ReportFilterText) { }

            column(Variant_Code; LSCTB."Variant Code") { }
            column(Store_No_TransSale; LSCTB."Store No.") { }
            column(Division_Code_TransSale; LSCTB."Division Code") { }
            column(Division_TransSale; LSCTB."Posting Exception Key") { }
            column(Receipt_No_TransSale; LSCTB."Receipt No.") { }
            column(Date_TransSale; Format(LSCTB.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(TransType; TransType) { }
            column(Item_No_TransSale; LSCTB."Item No.") { }
            column(Item_Name_ItemTB; ItemName) { }
            column(Qty; LSCTB.Quantity) { }
            column(Unit_of_Measure_TransSale; LSCTB."Unit of Measure") { }
            column(BaseQty; LSCTB."UOM Quantity") { }
            column(UnitPrice; LSCTB.Price) { }
            column(Amount; LSCTB.Price * LSCTB.Quantity) { }
            column(Discount_Amount_TransSale; LSCTB."Discount Amount") { }
            column(TotalAmt; LSCTB."Net Amount") { }
            column(ShowVariant; not RettailSetup."PLSPOS_Show Var for Report VIP") { }

            // ==========================================
            // 2. คอลัมน์รวมระดับกลุ่มสินค้า (Item Group Totals)
            // ==========================================
            column(ItemTotal_Qty; ItemTotal_Qty) { }
            column(ItemTotal_BaseQty; ItemTotal_BaseQty) { }
            column(ItemTotal_Amount; ItemTotal_Amount) { }
            column(ItemTotal_Discount; ItemTotal_Discount) { }
            column(ItemTotal_TotalAmount; ItemTotal_TotalAmount) { }
            // ==========================================
            // 3. คอลัมน์รวมระดับกลุ่มแผนก (Division Group Totals)
            // ==========================================
            column(DivTotal_Qty; DivTotal_Qty) { }
            column(DivTotal_Amount; DivTotal_Amount) { }
            column(DivTotal_Discount; DivTotal_Discount) { }
            column(DivTotal_TotalAmount; DivTotal_TotalAmount) { }
            // ==========================================
            // 4. คอลัมน์ยอดรวมสุทธิท้ายรายงาน (Grand Totals)
            // ==========================================
            column(GrandTotal_Qty; GrandTotal_Qty) { }
            column(GrandTotal_Amount; GrandTotal_Amount) { }
            column(GrandTotal_Discount; GrandTotal_Discount) { }
            column(GrandTotal_TotalAmount; GrandTotal_TotalAmount) { }
            trigger OnPreDataItem()
            var
                ItemKey: Text;
                DivKey: Text;
                CalcAmount: Decimal;
                Qty: Decimal;
                BaseQty: Decimal;
                UnitPrice: Decimal;
            begin
                LSCTB.Reset();
                LSCTB.DeleteAll();

                Clear(DictItemQty);
                Clear(DictItemBaseQty);
                Clear(DictItemAmt);
                Clear(DictItemDisc);
                Clear(DictItemTotalAmt);
                Clear(DictDivTotalAmt);
                Clear(DictDivQty);
                Clear(DictDivAmt);
                Clear(DictDivDisc);
                Clear(DictItemName);
                Clear(ItemName);
                Clear(TransType);
                Clear(DictTransType);
                // เคลียร์ค่า Grand Total ท้ายรายงาน
                GrandTotal_Qty := 0;
                GrandTotal_Amount := 0;
                GrandTotal_Discount := 0;
                GrandTotal_TotalAmount := 0;
                RettailSetup.Get();

                ReportFilterText := '';

                if Choose1Filter then begin
                    PeriodDate := 'ประจำงวดวันที่ ' + Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    PosSalesQry.SetFilter(DateFilter, '%1..%2', FromDateFilter, TodateFilter);
                end else if Choose2Filter then begin
                    PeriodDate := 'ประจำงวดวันที่ ' + Format(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    PosSalesQry.SetFilter(DateFilter, '%1', FDateFilter);
                end;

                if StoreFilter <> '' then begin
                    PosSalesQry.SetFilter(StoreNoFilter, StoreFilter);
                    ReportFilterText += 'Store No : ' + FORMAT(StoreFilter + ' ');
                end;

                if ItemNoFilter <> '' then begin
                    PosSalesQry.SetFilter(ItemNoFilter, ItemNoFilter);
                    ReportFilterText += ' Item No: ' + FORMAT(ItemNoFilter + ' ');
                end;

                if DivisionCodeFilter <> '' then begin
                    PosSalesQry.SetFilter(DivisionCodeFilter, DivisionCodeFilter);
                    ReportFilterText += ' Division Code : ' + FORMAT(DivisionCodeFilter + ' ');
                end;
                PosSalesQry.Open();

                while PosSalesQry.Read() do begin

                    ItemKey := PosSalesQry.Store_No + '_' + PosSalesQry.LSC_Division_Code + '_' + PosSalesQry.Item_No;
                    DivKey := PosSalesQry.Store_No + '_' + PosSalesQry.LSC_Division_Code;
                    LineKey := PosSalesQry.Store_No + '_' + PosSalesQry.POS_Terminal_No + '_' + Format(PosSalesQry.Transaction_No) + '_' + Format(PosSalesQry.Line_No);
                    if PosSalesQry.UOM_Quantity <> 0 then
                        Qty := -PosSalesQry.UOM_Quantity
                    else
                        Qty := -PosSalesQry.Quantity;

                    BaseQty := -PosSalesQry.Quantity;

                    if PosSalesQry.UOM_Price <> 0 then
                        UnitPrice := PosSalesQry.UOM_Price
                    else
                        UnitPrice := PosSalesQry.Price;

                    CalcAmount := (UnitPrice * Qty) - PosSalesQry.Discount_Amount;

                    TempTransType := Format(PosSalesQry.Transaction_Type);
                    if PosSalesQry.Return_No_Sale then
                        TempTransType := 'Refund';

                    if DictItemQty.ContainsKey(ItemKey) then begin
                        DictItemQty.Set(ItemKey, DictItemQty.Get(ItemKey) + Qty);
                        DictItemBaseQty.Set(ItemKey, DictItemBaseQty.Get(ItemKey) + BaseQty);
                        DictItemAmt.Set(ItemKey, DictItemAmt.Get(ItemKey) + (UnitPrice * Qty));
                        DictItemDisc.Set(ItemKey, DictItemDisc.Get(ItemKey) + PosSalesQry.Discount_Amount);
                        DictItemTotalAmt.Set(ItemKey, DictItemTotalAmt.Get(ItemKey) + (UnitPrice * Qty) - PosSalesQry.Discount_Amount);
                    end else begin
                        DictItemQty.Add(ItemKey, Qty);
                        DictItemBaseQty.Add(ItemKey, BaseQty);
                        DictItemAmt.Add(ItemKey, (UnitPrice * Qty));
                        DictItemDisc.Add(ItemKey, PosSalesQry.Discount_Amount);
                        DictItemTotalAmt.Add(ItemKey, (UnitPrice * Qty) - PosSalesQry.Discount_Amount);
                    end;

                    if DictDivQty.ContainsKey(DivKey) then begin
                        DictDivQty.Set(DivKey, DictDivQty.Get(DivKey) + Qty);
                        DictDivAmt.Set(DivKey, DictDivAmt.Get(DivKey) + (UnitPrice * Qty));
                        DictDivDisc.Set(DivKey, DictDivDisc.Get(DivKey) + PosSalesQry.Discount_Amount);
                        DictDivTotalAmt.Set(DivKey, DictDivTotalAmt.Get(DivKey) + (UnitPrice * Qty) - PosSalesQry.Discount_Amount);
                    end else begin
                        DictDivQty.Add(DivKey, Qty);
                        DictDivAmt.Add(DivKey, (UnitPrice * Qty));
                        DictDivDisc.Add(DivKey, PosSalesQry.Discount_Amount);
                        DictDivTotalAmt.Add(DivKey, (UnitPrice * Qty) - PosSalesQry.Discount_Amount);
                    end;

                    if not DictItemName.ContainsKey(PosSalesQry.Item_No) then
                        DictItemName.Add(PosSalesQry.Item_No, PosSalesQry.Item_Description + ' ' + PosSalesQry.Item_Description_2);
                    if not DictTransType.ContainsKey(LineKey) then
                        DictTransType.Add(LineKey, TempTransType);

                    GrandTotal_Qty += Qty;
                    GrandTotal_Amount += (UnitPrice * Qty);
                    GrandTotal_Discount += PosSalesQry.Discount_Amount;
                    GrandTotal_TotalAmount += (UnitPrice * Qty) - PosSalesQry.Discount_Amount;
                    LSCTB.Init();
                    LSCTB."Store No." := PosSalesQry.Store_No;
                    LSCTB."POS Terminal No." := PosSalesQry.POS_Terminal_No;
                    LSCTB."Transaction No." := PosSalesQry.Transaction_No;
                    LSCTB."Line No." := PosSalesQry.Line_No;
                    LSCTB."Variant Code" := PosSalesQry.Variant_Code;
                    LSCTB."Receipt No." := PosSalesQry.Receipt_No;
                    LSCTB.Date := PosSalesQry.Date;
                    LSCTB."Item No." := PosSalesQry.Item_No;
                    LSCTB."Division Code" := PosSalesQry.LSC_Division_Code;
                    LSCTB."Posting Exception Key" := PosSalesQry.LSC_Division_Code + ' - ' + PosSalesQry.Division_Description;
                    LSCTB.Quantity := Qty;
                    LSCTB.Price := UnitPrice;
                    LSCTB."Discount Amount" := PosSalesQry.Discount_Amount;
                    LSCTB."Unit of Measure" := PosSalesQry.Unit_of_Measure;
                    LSCTB."UOM Quantity" := BaseQty;
                    LSCTB."Net Amount" := CalcAmount;
                    LSCTB.Insert();
                end;
                PosSalesQry.Close();
                LSCTB.SetCurrentKey("Store No.", "Division Code", "Item No.", "POS Terminal No.", "Transaction No.", "Line No.");
                TransSale.SetRange(Number, 1, LSCTB.Count());
            end;

            trigger OnAfterGetRecord()
            var
                ItemKey: Text;
                DivKey: Text;
            begin
                if Number = 1 then begin
                    if not LSCTB.FindSet() then
                        CurrReport.Break();
                end else begin
                    if LSCTB.Next() = 0 then
                        CurrReport.Break();
                end;

                ItemKey := LSCTB."Store No." + '_' + LSCTB."Division Code" + '_' + LSCTB."Item No.";
                DivKey := LSCTB."Store No." + '_' + LSCTB."Division Code";

                // ดึงยอดรวมกลุ่มสินค้า (Item Group) ออกมาใส่คอลัมน์
                if DictItemQty.ContainsKey(ItemKey) then begin
                    ItemTotal_Qty := DictItemQty.Get(ItemKey);
                    ItemTotal_BaseQty := DictItemBaseQty.Get(ItemKey);
                    ItemTotal_Amount := DictItemAmt.Get(ItemKey);
                    ItemTotal_Discount := DictItemDisc.Get(ItemKey);
                    ItemTotal_TotalAmount := DictItemTotalAmt.Get(ItemKey);
                end else begin
                    ItemTotal_Qty := 0;
                    ItemTotal_BaseQty := 0;
                    ItemTotal_Amount := 0;
                    ItemTotal_Discount := 0;
                    ItemTotal_TotalAmount := 0;
                end;

                // ดึงยอดรวมกลุ่มแผนก (Division Group) ออกมาใส่คอลัมน์
                if DictDivQty.ContainsKey(DivKey) then begin
                    DivTotal_Qty := DictDivQty.Get(DivKey);
                    DivTotal_Amount := DictDivAmt.Get(DivKey);
                    DivTotal_Discount := DictDivDisc.Get(DivKey);
                    DivTotal_TotalAmount := DictDivTotalAmt.Get(DivKey);
                end else begin
                    DivTotal_Qty := 0;
                    DivTotal_Amount := 0;
                    DivTotal_Discount := 0;
                    DivTotal_TotalAmount := 0;
                end;

                if DictItemName.ContainsKey(LSCTB."Item No.") then
                    ItemName := DictItemName.Get(LSCTB."Item No.")
                else
                    ItemName := '';

                LineKey := LSCTB."Store No." + '_' + LSCTB."POS Terminal No." + '_' + Format(LSCTB."Transaction No.") + '_' + Format(LSCTB."Line No.");
                if DictTransType.ContainsKey(LineKey) then
                    TransType := DictTransType.Get(LineKey)
                else
                    TransType := '';
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
                        field("Division Code :"; DivisionCodeFilter)
                        {
                            ApplicationArea = All;
                            TableRelation = "LSC Division".Code;
                            Caption = 'Division Code :';
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
        PosSalesQry: Query "PLSR_Sales Report By DivisionQ";
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        RettailSetup: Record "LSC Retail Setup";
        LSCTB: Record "LSC Trans. Sales Entry" temporary;
        ShowTime: Text[50];
        ShowDate: Text[50];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        TransType: Text[50];
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        DivisionCodeFilter: Text[50];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        ItemName: Text[150];
        DictItemQty: Dictionary of [Text, Decimal];
        DictItemBaseQty: Dictionary of [Text, Decimal];
        DictItemAmt: Dictionary of [Text, Decimal];
        DictItemDisc: Dictionary of [Text, Decimal];
        DictItemTotalAmt: Dictionary of [Text, Decimal];
        DictItemName: Dictionary of [Code[20], Text[150]];
        DictDivQty: Dictionary of [Text, Decimal];
        DictDivAmt: Dictionary of [Text, Decimal];
        DictDivDisc: Dictionary of [Text, Decimal];
        DictDivTotalAmt: Dictionary of [Text, Decimal];
        DictTransType: Dictionary of [Text, Text];
        LineKey: Text;
        TempTransType: Text[50];
        ItemTotal_Qty: Decimal;
        ItemTotal_BaseQty: Decimal;
        ItemTotal_Amount: Decimal;
        ItemTotal_Discount: Decimal;
        ItemTotal_TotalAmount: Decimal;
        DivTotal_Qty: Decimal;
        DivTotal_Amount: Decimal;
        DivTotal_Discount: Decimal;
        DivTotal_TotalAmount: Decimal;
        GrandTotal_Qty: Decimal;
        GrandTotal_Amount: Decimal;
        GrandTotal_Discount: Decimal;
        GrandTotal_TotalAmount: Decimal;
}