report 50102 "Sales Rep by Sale Staff"
{
    Caption = 'POS Sales Report by Sale Staff_Test';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50102_POSSalesReportByStaff.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
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
            column(Sales_Staff_TransSale; CurrentSalesStaff) { }
            column(Sales_Staff_Name; CurrentStaffName) { }
            column(Receipt_No_TransSale; CurrentReceiptNo) { }
            column(Date_TransSale; CurrentDate) { }
            column(TransType; CurrentTransType) { }
            column(CancelDocNo; CurrentCancelDocNo) { }
            column(RefundDocNo; CurrentRefundDocNo) { }
            column(RefRefund; CurrentRefRefund) { }
            column(Item_No_TransSale; CurrentItemNo) { }
            column(Item_Name_ItemTB; CurrentItemName) { }
            column(Contact_No_MemberContact; CurrentCardNo) { }
            column(Name_MemberContact; CurrentMemberName) { }
            column(Unit_of_Measure_TransSale; CurrentUOM) { }
            column(Qty; CurrentQty) { }
            column(BaseQty; CurrentBaseQty) { }
            column(UnitPrice; CurrentUnitPrice) { }
            column(Amount; CurrentAmount) { }
            column(Discount_Amount_TransSale; CurrentDiscountAmt) { }
            column(TotalAmt; CurrentTotalAmt) { }
            column(CountBill; CurrentCountBill) { }
            column(ShowVariant; CurrentShowVariant) { }

            trigger OnPreDataItem()
            begin
                // Refund filter
                case RefundFilter of
                    RefundFilter::Yes:
                        QuerySalesStaff.SetFilter(ReturnNoSaleFilter, '%1', true);
                    RefundFilter::No:
                        QuerySalesStaff.SetFilter(ReturnNoSaleFilter, '%1', false);
                end;

                // Date filter
                if Choose1Filter then begin
                    QuerySalesStaff.SetFilter(DateFilter, '%1..%2', FromDateFilter, TodateFilter);
                    PeriodDate := 'ประจำงวดวันที่ ' + Format(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') +
                                  ' ถึง ' + Format(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                end else
                    if Choose2Filter then begin
                        QuerySalesStaff.SetFilter(DateFilter, '%1', FDateFilter);
                        PeriodDate := 'ประจำงวดวันที่ ' + Format(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    end;

                // Data filters
                if StoreFilter <> '' then begin
                    QuerySalesStaff.SetFilter(StoreNoFilter, StoreFilter);
                    ReportFilterText += ' Store No : ' + StoreFilter + ' ';
                end;
                if ItemNoFilter <> '' then begin
                    QuerySalesStaff.SetFilter(ItemNoFilter, ItemNoFilter);
                    ReportFilterText += ' Item No: ' + ItemNoFilter + ' ';
                end;
                if SaleStaffNoFilter <> '' then begin
                    QuerySalesStaff.SetFilter(SaleStaffFilter, SaleStaffNoFilter);
                    ReportFilterText += ' Sales Staff : ' + SaleStaffNoFilter + ' ';
                end;

                RettailSetup.Get();
                QuerySalesStaff.Open();
            end;

            trigger OnAfterGetRecord()
            begin
                if not QuerySalesStaff.Read() then
                    CurrReport.Break();

                // Qty / Price
                if QuerySalesStaff.UOM_Quantity <> 0 then
                    CurrentQty := -QuerySalesStaff.UOM_Quantity
                else
                    CurrentQty := -QuerySalesStaff.Quantity;

                if QuerySalesStaff.UOM_Price <> 0 then
                    CurrentUnitPrice := QuerySalesStaff.UOM_Price
                else
                    CurrentUnitPrice := QuerySalesStaff.Price;

                CurrentBaseQty := -QuerySalesStaff.Quantity;
                CurrentDiscountAmt := QuerySalesStaff.Discount_Amount;
                CurrentAmount := CurrentUnitPrice * CurrentQty;
                CurrentTotalAmt := CurrentAmount - CurrentDiscountAmt;

                // TransType / Doc No.
                CurrentTransType := Format(QuerySalesStaff.Transaction_Type);
                CurrentCancelDocNo := '';
                CurrentRefundDocNo := '';
                if QuerySalesStaff.Return_No_Sale then
                    CurrentTransType := 'Refund';
                if QuerySalesStaff.Sale_Is_Return_Sale then
                    CurrentRefundDocNo := 'Refund Manual';
                if QuerySalesStaff.Retrieved_From_Receipt_No <> '' then
                    CurrentRefundDocNo := QuerySalesStaff.Retrieved_From_Receipt_No;
                if QuerySalesStaff.Refund_Receipt_No <> '' then
                    CurrentCancelDocNo := QuerySalesStaff.Refund_Receipt_No;

                // CountBill — นับใบเมื่อเปลี่ยน Receipt No.
                CurrentCountBill := 0;
                if CurrentReceiptNo <> QuerySalesStaff.Receipt_No_ then
                    CurrentCountBill := 1;

                // Display fields
                CurrentStoreNo := QuerySalesStaff.Store_No_;
                CurrentReceiptNo := QuerySalesStaff.Receipt_No_;
                CurrentDate := QuerySalesStaff.Date_;
                CurrentItemNo := QuerySalesStaff.Item_No_;
                CurrentUOM := QuerySalesStaff.Unit_of_Measure;
                CurrentVariantCode := QuerySalesStaff.Variant_Code;
                CurrentSalesStaff := QuerySalesStaff.Sales_Staff;
                CurrentItemName := QuerySalesStaff.Item_Description + ' ' + QuerySalesStaff.Item_Description2;
                CurrentStaffName := QuerySalesStaff.Staff_First_Name + ' ' + QuerySalesStaff.Staff_Last_Name;
                CurrentCardNo := QuerySalesStaff.Card_No;
                CurrentMemberName := QuerySalesStaff.Member_Name + ' ' + QuerySalesStaff.Member_Name2;
                CurrentRefRefund := QuerySalesStaff.Ref_Refund_Receipt_No;
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
                        field("Sale Staff :"; SaleStaffNoFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'Sale Staff :';
                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                Clear(StaffLookupTB);
                                if StoreFilter <> '' then
                                    StaffLookupTB.SetRange("Store No.", StoreFilter);
                                if StaffLookupTB.FindSet() then
                                    if Page.RunModal(PAGE::"LSC Staff List", StaffLookupTB) = Action::LookupOK then
                                        SaleStaffNoFilter := StaffLookupTB.ID;
                            end;
                        }
                        field("Refund Transaction :"; RefundFilter)
                        {
                            Caption = 'Refund Transaction :';
                            OptionCaption = ' ,Yes,No';
                            ApplicationArea = All;
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
        StaffLookupTB: Record "LSC Staff";
        QuerySalesStaff: Query "PLSR_Sales By Sale Staff Q";
        ShowTime: Text[50];
        ShowDate: Text[50];
        PeriodDate: Text[150];
        ReportFilterText: Text[250];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        SaleStaffNoFilter: Code[20];
        RefundFilter: Option " ","Yes","No";
        CurrentStoreNo: Code[20];
        CurrentReceiptNo: Code[20];
        CurrentItemNo: Code[20];
        CurrentUOM: Code[10];
        CurrentVariantCode: Code[20];
        CurrentSalesStaff: Code[20];
        CurrentCardNo: Code[20];
        CurrentTransType: Text[50];
        CurrentCancelDocNo: Text[30];
        CurrentRefundDocNo: Text[30];
        CurrentRefRefund: Text[30];
        CurrentItemName: Text[200];
        CurrentStaffName: Text[100];
        CurrentMemberName: Text[200];
        CurrentDate: Date;
        CurrentQty: Decimal;
        CurrentBaseQty: Decimal;
        CurrentUnitPrice: Decimal;
        CurrentAmount: Decimal;
        CurrentDiscountAmt: Decimal;
        CurrentTotalAmt: Decimal;
        CurrentCountBill: Decimal;
        CurrentShowVariant: Boolean;
}