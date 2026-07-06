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
            DataItemTableView = sorting(Number);

            column(Variant_Code; SalesQuery.Variant_Code) { }
            column(Name_ComInfo; ComInfo.Name) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(PeriodDate; PeriodDate) { }
            column(ReportFilterText; ReportFilterText) { }
            column(Store_No_TransSale; SalesQuery.Store_No) { }
            column(Item_Category_Code_TransSale; SalesQuery.Item_Category_Code) { }
            column(Item_Category_TransSale; ItemCategoryText) { }
            column(Receipt_No_TransSale; SalesQuery.Receipt_No) { }
            column(Date_TransSale; Format(SalesQuery.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(TransType; TransType) { }
            column(Item_No_TransSale; SalesQuery.Item_No) { }
            column(Item_Name_ItemTB; SalesQuery.Item_Description + ' ' + SalesQuery.Item_Description_2) { }
            column(Unit_of_Measure_TransSale; SalesQuery.Unit_of_Measure) { }
            column(Qty; Qty) { }
            column(BaseQty; BaseQty) { }
            column(UnitPrice; UnitPrice) { }
            column(Amount; UnitPrice * Qty) { }
            column(Discount_Amount_TransSale; SalesQuery.Discount_Amount) { }
            column(TotalAmt; (UnitPrice * Qty) - SalesQuery.Discount_Amount) { }
            column(ShowVariant; not RettailSetup."PLSPOS_Show Var for Report VIP") { }

            trigger OnPreDataItem()
            begin

                IF Choose1Filter THEN BEGIN
                    DateFilter := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                END
                ELSE
                    IF Choose2Filter THEN BEGIN
                        DateFilter := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    END;

                IF (StoreFilter <> '') THEN
                    ReportFilterText += 'Store No : ' + FORMAT(StoreFilter + ' ');
                IF (ItemNoFilter <> '') THEN
                    ReportFilterText += ' Item No: ' + FORMAT(ItemNoFilter + ' ');
                IF (ItemCatFilter <> '') THEN
                    ReportFilterText += ' Item Category Code : ' + FORMAT(ItemCatFilter + ' ');

                RettailSetup.Get();


                Clear(SalesQuery);
                if DateFilter <> '' then
                    SalesQuery.SetFilter(DateFilter, DateFilter);
                if StoreFilter <> '' then
                    SalesQuery.SetFilter(StoreNoFilter, StoreFilter);
                if ItemNoFilter <> '' then
                    SalesQuery.SetFilter(ItemNoFilter, ItemNoFilter);
                if ItemCatFilter <> '' then
                    SalesQuery.SetFilter(ItemCategoryFilter, ItemCatFilter);


                SalesQuery.Open();
            end;

            trigger OnAfterGetRecord()
            begin

                if not SalesQuery.Read() then
                    CurrReport.Break();


                ItemCategoryText := SalesQuery.Item_Category_Code + ' - ' + SalesQuery.Category_Description;

                TransType := Format(SalesQuery.Transaction_Type);
                if SalesQuery.Return_No_Sale then
                    TransType := 'Refund';

                Clear(Qty);
                Clear(BaseQty);
                Clear(UnitPrice);

                if SalesQuery.UOM_Quantity <> 0 then
                    Qty := -SalesQuery.UOM_Quantity
                else
                    Qty := -SalesQuery.Quantity;

                if SalesQuery.UOM_Price <> 0 then
                    UnitPrice := SalesQuery.UOM_Price
                else
                    UnitPrice := SalesQuery.Price;

                BaseQty := -SalesQuery.Quantity;
            end;

            trigger OnPostDataItem()
            begin

                SalesQuery.Close();
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

        ItemCategoryText: Text[250];
        ShowTime: Text[50];
        ShowDate: Text[50];
        DateFilter: Text[100];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        TransType: Text[50];
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        ItemCatFilter: Code[20];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        Qty: Decimal;
        BaseQty: Decimal;
        UnitPrice: Decimal;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
}