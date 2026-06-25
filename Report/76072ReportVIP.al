report 50101 "Sales Report By ProdGroup"
{
    Caption = 'POS Sales Report By Product Group_Test';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50101_POSSalesReportByProdGroup.rdl';
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

            column(Variant_Code; CurrentVariantCode) { }
            column(Name_ComInfo; ComInfo.Name) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(PeriodDate; PeriodDate) { }
            column(ReportFilterText; ReportFilterText) { }
            column(Store_No_TransSale; CurrentStoreNo) { }
            column(Retail_Product_Code_TransSale; CurrentProdCode) { }
            column(Retail_Product_TransSale; CurrentProdDisplay) { }
            column(Receipt_No_TransSale; CurrentReceiptNo) { }
            column(Date_TransSale; CurrentDateDisplay) { }
            column(TransType; CurrentTransType) { }
            column(Item_No_TransSale; CurrentItemNo) { }
            column(Item_Name_ItemTB; CurrentItemName) { }
            column(Unit_of_Measure_TransSale; CurrentUOM) { }
            column(Qty; CurrentQty) { }
            column(BaseQty; CurrentBaseQty) { }
            column(UnitPrice; CurrentUnitPrice) { }
            column(Amount; CurrentAmount) { }
            column(Discount_Amount_TransSale; CurrentDiscountAmt) { }
            column(TotalAmt; CurrentTotalAmt) { }
            column(ShowVariant; CurrentShowVariant) { }

            trigger OnPreDataItem()
            begin
                // Date filter
                if Choose1Filter then begin
                    QuerySalesProdGroup.SetFilter(DateFilter, '%1..%2', FromDateFilter, TodateFilter);
                    PeriodDate := 'ประจำงวดวันที่ ' + Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') +
                                  ' ถึง ' + Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                end else
                    if Choose2Filter then begin
                        QuerySalesProdGroup.SetFilter(DateFilter, '%1', FDateFilter);
                        PeriodDate := 'ประจำงวดวันที่ ' + Format(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    end;

                // รับ filter จาก RequestFilterFields ของ dataitem หลอก
                // if TransSaleFilter.GetFilter("Store No.") <> '' then begin
                //     QuerySalesProdGroup.SetFilter(StoreNoFilter, TransSaleFilter.GetFilter("Store No."));
                //     ReportFilterText += 'Store No : ' + TransSaleFilter.GetFilter("Store No.") + ' ';
                // end;
                // if TransSaleFilter.GetFilter("Item No.") <> '' then begin
                //     QuerySalesProdGroup.SetFilter(ItemNoFilter, TransSaleFilter.GetFilter("Item No."));
                //     ReportFilterText += ' Item No: ' + TransSaleFilter.GetFilter("Item No.") + ' ';
                // end;
                // if TransSaleFilter.GetFilter("Retail Product Code") <> '' then begin
                //     QuerySalesProdGroup.SetFilter(ProductGroupFilter, TransSaleFilter.GetFilter("Retail Product Code"));
                //     ReportFilterText += ' Product Group Code : ' + TransSaleFilter.GetFilter("Retail Product Code") + ' ';
                // end;
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

                // ส่ง filter จากตัวแปรใน requestpage ไปให้ Query โดยตรง
                RettailSetup.Get();
                QuerySalesProdGroup.Open();
            end;

            trigger OnAfterGetRecord()
            begin
                if not QuerySalesProdGroup.Read() then
                    CurrReport.Break();

                // Qty / Price
                if QuerySalesProdGroup.UOM_Quantity <> 0 then
                    CurrentQty := -QuerySalesProdGroup.UOM_Quantity
                else
                    CurrentQty := -QuerySalesProdGroup.Quantity;

                if QuerySalesProdGroup.UOM_Price <> 0 then
                    CurrentUnitPrice := QuerySalesProdGroup.UOM_Price
                else
                    CurrentUnitPrice := QuerySalesProdGroup.Price;

                CurrentBaseQty := -QuerySalesProdGroup.Quantity;
                CurrentDiscountAmt := QuerySalesProdGroup.Discount_Amount;
                CurrentAmount := CurrentUnitPrice * CurrentQty;
                CurrentTotalAmt := CurrentAmount - CurrentDiscountAmt;

                // TransType
                CurrentTransType := Format(QuerySalesProdGroup.Transaction_Type);
                if QuerySalesProdGroup.Return_No_Sale then
                    CurrentTransType := 'Refund';

                // Display fields
                CurrentDateDisplay := Format(QuerySalesProdGroup.Date_, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                CurrentItemName := QuerySalesProdGroup.Item_Description + ' ' + QuerySalesProdGroup.Item_Description2;
                CurrentProdDisplay := QuerySalesProdGroup.Retail_Product_Code + ' - ' + QuerySalesProdGroup.ProdGroup_Description;
                CurrentStoreNo := QuerySalesProdGroup.Store_No_;
                CurrentProdCode := QuerySalesProdGroup.Retail_Product_Code;
                CurrentReceiptNo := QuerySalesProdGroup.Receipt_No_;
                CurrentItemNo := QuerySalesProdGroup.Item_No_;
                CurrentUOM := QuerySalesProdGroup.Unit_of_Measure;
                CurrentVariantCode := QuerySalesProdGroup.Variant_Code;
                CurrentShowVariant := not RettailSetup."PLSPOS_Show Var for Report VIP";
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
        ShowTime: Text[50];
        ShowDate: Text[50];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        CurrentStoreNo: Code[20];
        CurrentProdCode: Code[20];
        CurrentReceiptNo: Code[20];
        CurrentItemNo: Code[20];
        CurrentUOM: Code[10];
        CurrentVariantCode: Code[20];
        CurrentTransType: Text[50];
        CurrentDateDisplay: Text[20];
        CurrentItemName: Text[200];
        CurrentProdDisplay: Text[200];
        CurrentQty: Decimal;
        CurrentBaseQty: Decimal;
        CurrentUnitPrice: Decimal;
        CurrentAmount: Decimal;
        CurrentDiscountAmt: Decimal;
        CurrentTotalAmt: Decimal;
        CurrentShowVariant: Boolean;
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        ProductGroupFilter: Code[20];
}