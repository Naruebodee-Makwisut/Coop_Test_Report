report 50106 "PLSR_Sales Report By Division2"
{
    Caption = 'POS Sales Report By Division';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep76070_POSSalesReportByDivision.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem(TransSale; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter('1..'));

            column(Variant_Code; PosSalesQry.Variant_Code) { } // PosSalesQry. คือการดึงข้อมูลจาก Query แทนดึงตรงๆจาก Table
            column(Name_ComInfo; ComInfo.Name) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(PeriodDate; PeriodDate) { }
            column(ReportFilterText; ReportFilterText) { }
            column(Store_No_TransSale; PosSalesQry.Store_No) { }
            column(Division_Code_TransSale; PosSalesQry.LSC_Division_Code) { }
            column(Division_TransSale; PosSalesQry.Division_Code + ' - ' + PosSalesQry.Division_Description) { }

            column(Receipt_No_TransSale; PosSalesQry.Receipt_No) { }
            column(Date_TransSale; Format(PosSalesQry.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(TransType; TransType) { }
            column(Item_No_TransSale; PosSalesQry.Item_No) { }
            column(Item_Name_ItemTB; PosSalesQry.Item_Description + ' ' + PosSalesQry.Item_Description_2) { }

            column(Unit_of_Measure_TransSale; PosSalesQry.Unit_of_Measure) { }
            column(Qty; Qty) { }
            column(BaseQty; BaseQty) { }
            column(UnitPrice; UnitPrice) { }
            column(Amount; UnitPrice * Qty) { }
            column(Discount_Amount_TransSale; PosSalesQry.Discount_Amount) { }
            column(TotalAmt; (UnitPrice * Qty) - PosSalesQry.Discount_Amount) { }
            column(ShowVariant; not RettailSetup."PLSPOS_Show Var for Report VIP") { }

            trigger OnPreDataItem()
            begin
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
                    ReportFilterText += 'Store No : ' + StoreFilter + ' ';
                end;

                if ItemNoFilter <> '' then begin
                    PosSalesQry.SetFilter(ItemNoFilter, ItemNoFilter);
                    ReportFilterText += ' Item No: ' + ItemNoFilter + ' ';
                end;

                if DivisionCodeFilter <> '' then begin
                    PosSalesQry.SetFilter(DivisionCodeFilter, DivisionCodeFilter);
                    ReportFilterText += ' Division Code : ' + DivisionCodeFilter + ' ';
                end;
                Clear(TransType); //เคลียร์ตัวแปรไว้ก่อน
                Clear(Qty);
                Clear(UnitPrice);
                Clear(BaseQty);
                PosSalesQry.Open();
            end;

            trigger OnAfterGetRecord()
            begin

                if not PosSalesQry.Read() then
                    CurrReport.Break();

                TransType := Format(PosSalesQry.Transaction_Type);
                if PosSalesQry.Return_No_Sale then
                    TransType := 'Refund';

                if PosSalesQry.UOM_Quantity <> 0 then
                    Qty := -PosSalesQry.UOM_Quantity
                else
                    Qty := -PosSalesQry.Quantity;

                if PosSalesQry.UOM_Price <> 0 then
                    UnitPrice := PosSalesQry.UOM_Price
                else
                    UnitPrice := PosSalesQry.Price;

                BaseQty := -PosSalesQry.Quantity;
            end;

            trigger OnPostDataItem()
            begin
                PosSalesQry.Close();
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
        PosSalesQry: Query "PLSR_Sales Report By DivisionQ"; //ตัวแปรรับคิวรี่มาใช้งาน ไม่ต้องดึง table เยอะ
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        // ItemTB: Record Item; ไปอยู่ในคิวรี่แทนแล้ว
        //  DivisonTB: Record "LSC Division";
        // TransHeaderTB: Record "LSC Transaction Header";
        RettailSetup: Record "LSC Retail Setup";

        ShowTime: Text[50];
        ShowDate: Text[50];
        DateFilter: Text[100];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        TransType: Text[50];
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        DivisionCodeFilter: Text[50];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        Qty: Decimal;
        BaseQty: Decimal;
        UnitPrice: Decimal;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;

}