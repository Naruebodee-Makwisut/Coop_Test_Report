report 50109 "Sales_Report_By_Terminal"
{
    Caption = 'POS Sales Report by Terminal';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50109_POSSalesReportByTerminal.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem(TransSale; "LSC Trans. Sales Entry")
        {
            DataItemTableView = sorting("Store No.", "POS Terminal No.", "Transaction No.", "Line No.");

            column(Variant_Code; "Variant Code") { }
            column(Name_ComInfo; ComInfo.Name) { }
            column(ShowDate; ShowDate) { }
            column(ShowTime; ShowTime) { }
            column(PeriodDate; PeriodDate) { }
            column(ReportFilterText; ReportFilterText) { }
            column(Store_No_TransSale; TransSale."Store No.") { }
            column(POS_Terminal_No_TransSale; TransSale."POS Terminal No.") { }
            column(Receipt_No_TransSale; TransSale."Receipt No.") { }
            column(Date_TransSale; format(TransSale.Date, 0, '<Closing><Day,2>/<Month,2>/<Year4>')) { }
            column(TransType; TransType) { }
            column(CancelDocNo; CancelDocNo) { }
            column(RefundDocNo; RefundDocNo) { }
            column(RefRefund; TransHeaderTB."PLSPOS_Ref. Refund Receipt No.") { }
            column(Item_No_TransSale; TransSale."Item No.") { }
            column(Item_Name_ItemTB; ItemTB.Description + ' ' + ItemTB."Description 2") { }
            column(Contact_No_MemberContact; MemberShipCardTB."Card No.") { }
            column(Name_MemberContact; MemberContactTB.Name + ' ' + MemberContactTB."Name 2") { }
            column(Unit_of_Measure_TransSale; TransSale."Unit of Measure") { }
            column(Qty; Qty) { }
            column(BaseQty; BaseQty) { }
            column(UnitPrice; UnitPrice) { }
            column(Amount; UnitPrice * Qty) { }
            column(Discount_Amount_TransSale; TransSale."Discount Amount") { }
            column(TotalAmt; (UnitPrice * Qty) - TransSale."Discount Amount") { }
            column(ShowVariant; not RettailSetup."PLSPOS_Show Var for Report VIP") { }
            column(TransHeaderTB_Time; format(TransHeaderTB.Time)) { }

            trigger OnPreDataItem()
            begin
                // โหลดเฉพาะ field ที่ใช้จริง
                SetLoadFields(
                    "Store No.", "POS Terminal No.", "Transaction No.", "Line No.",
                    "Item No.", "Variant Code", "Receipt No.", Date,
                    "Unit of Measure", "UOM Quantity", "UOM Price",
                    Quantity, Price, "Discount Amount", "Return No Sale"
                );

                if RefundFilter = RefundFilter::Yes then
                    TransSale.SetRange("Return No Sale", true)
                else
                    if RefundFilter = RefundFilter::No then
                        TransSale.SetRange("Return No Sale", false);

                IF Choose1Filter THEN BEGIN
                    DateFilter := FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>') + '..'
                                  + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FromDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>')
                                  + ' ถึง ' + FORMAT(TodateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                END ELSE
                    IF Choose2Filter THEN BEGIN
                        DateFilter := FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                        PeriodDate := 'ประจำงวดวันที่ ' + FORMAT(FDateFilter, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
                    END;

                IF DateFilter <> '' THEN
                    TransSale.SETFILTER(Date, DateFilter);
                IF StoreFilter <> '' THEN
                    TransSale.SETFILTER("Store No.", StoreFilter);
                IF ItemNoFilter <> '' THEN
                    TransSale.SETFILTER("Item No.", ItemNoFilter);
                IF POSTerminalFilter <> '' THEN
                    TransSale.SETFILTER("POS Terminal No.", POSTerminalFilter);

                IF StoreFilter <> '' THEN
                    ReportFilterText += 'Store No : ' + FORMAT(StoreFilter + ' ');
                IF ItemNoFilter <> '' THEN
                    ReportFilterText += ' Item No: ' + FORMAT(ItemNoFilter + ' ');
                IF POSTerminalFilter <> '' THEN
                    ReportFilterText += ' POS Terminal No. : ' + FORMAT(POSTerminalFilter + ' ');

                RettailSetup.Get();

                // Reset cache
                Clear(LastStoreNo);
                Clear(LastItemNo);
                Clear(LastRefundReceiptNo);
                Clear(LastMemberCardNo);
                Clear(ReceiptNo);
            end;

            trigger OnAfterGetRecord()
            begin
                Clear(RefundDocNo);
                Clear(CancelDocNo);
                Clear(TransType);

                // ── Cache StoreTB ──
                if TransSale."Store No." <> LastStoreNo then begin
                    Clear(StoreTB);
                    StoreTB.SetLoadFields("No.");
                    if StoreTB.Get(TransSale."Store No.") then;
                    LastStoreNo := TransSale."Store No.";
                end;

                // ── Cache ItemTB ──
                if TransSale."Item No." <> LastItemNo then begin
                    Clear(ItemTB);
                    ItemTB.SetLoadFields("No.", Description, "Description 2");
                    if ItemTB.Get(TransSale."Item No.") then;
                    LastItemNo := TransSale."Item No.";
                end;

                // ── Cache TransHeaderTB ── (เดิมมีอยู่แล้ว เพิ่ม SetLoadFields)
                if ReceiptNo <> TransSale."Receipt No." then begin
                    ReceiptNo := TransSale."Receipt No.";
                    Clear(TransHeaderTB);
                    TransHeaderTB.SetCurrentKey("Store No.", "POS Terminal No.", "Transaction No.");
                    TransHeaderTB.SetRange("Store No.", TransSale."Store No.");
                    TransHeaderTB.SetRange("POS Terminal No.", TransSale."POS Terminal No.");
                    TransHeaderTB.SetRange("Transaction No.", TransSale."Transaction No.");
                    TransHeaderTB.SetLoadFields(
                        "Transaction Type", "Sale Is Return Sale",
                        "Retrieved from Receipt No.", "Refund Receipt No.",
                        "Member Card No.", Time,
                        "PLSPOS_Ref. Refund Receipt No."
                    );
                    if TransHeaderTB.FindFirst() then;
                end;

                TransType := Format(TransHeaderTB."Transaction Type");
                if TransSale."Return No Sale" then
                    TransType := 'Refund';
                if TransHeaderTB."Sale Is Return Sale" then
                    RefundDocNo := 'Refund Manual';
                if TransHeaderTB."Retrieved from Receipt No." <> '' then
                    RefundDocNo := TransHeaderTB."Retrieved from Receipt No.";
                if TransHeaderTB."Refund Receipt No." <> '' then
                    CancelDocNo := TransHeaderTB."Refund Receipt No.";

                // ── Cache TransHTb (void check) ──
                // Cache ด้วย Refund Receipt No. เพราะซ้ำถ้าหลาย line ในบิลเดียวกัน
                if CancelDocNo <> '' then begin
                    if CancelDocNo <> LastRefundReceiptNo then begin
                        Clear(TransHTb);
                        TransHTb.SetCurrentKey("Receipt No.");
                        TransHTb.SetRange("Receipt No.", CancelDocNo);
                        TransHTb.SetLoadFields("Receipt No.", "Entry Status");
                        LastRefundReceiptIsVoided := false;
                        if TransHTb.FindFirst() then
                            if TransHTb."Entry Status" = TransHTb."Entry Status"::Voided then
                                LastRefundReceiptIsVoided := true;
                        LastRefundReceiptNo := CancelDocNo;
                    end;
                    if LastRefundReceiptIsVoided then
                        CancelDocNo := '';
                end;

                // ── Cache MemberShipCard + MemberContact ──
                // Cache ด้วย Member Card No. เพราะหลาย line ในบิลเดียวกันใช้ Card เดียว
                if TransHeaderTB."Member Card No." <> LastMemberCardNo then begin
                    Clear(MemberShipCardTB);
                    Clear(MemberContactTB);
                    if TransHeaderTB."Member Card No." <> '' then begin
                        MemberShipCardTB.SetLoadFields("Card No.", "Account No.", "Contact No.");
                        if MemberShipCardTB.Get(TransHeaderTB."Member Card No.") then begin
                            MemberContactTB.SetLoadFields(Name, "Name 2");
                            if MemberContactTB.Get(MemberShipCardTB."Account No.", MemberShipCardTB."Contact No.") then;
                        end;
                    end;
                    LastMemberCardNo := TransHeaderTB."Member Card No.";
                end;

                // QTY / Price
                Clear(Qty);
                Clear(BaseQty);
                Clear(UnitPrice);

                if TransSale."UOM Quantity" <> 0 then
                    Qty := -TransSale."UOM Quantity"
                else
                    Qty := -TransSale.Quantity;

                if TransSale."UOM Price" <> 0 then
                    UnitPrice := TransSale."UOM Price"
                else
                    UnitPrice := TransSale.Price;

                BaseQty := -TransSale.Quantity;
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
                        field("POS Terminal No. :"; POSTerminalFilter)
                        {
                            ApplicationArea = All;
                            Caption = 'POS Terminal No. :';
                            trigger OnLookup(VAR Text: Text): Boolean
                            begin
                                Clear(POSTerminalTB);
                                if StoreFilter <> '' then
                                    POSTerminalTB.SetRange("Store No.", StoreFilter);
                                if POSTerminalTB.FindSet() then
                                    if Page.RunModal(Page::"LSC POS Terminal List", POSTerminalTB) = Action::LookupOK then
                                        POSTerminalFilter := POSTerminalTB."No.";
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
            FDateFilter := Today;
            Choose1Filter := false;
            Choose2Filter := true;
            SelectLatestVersion();
        end;
    }

    trigger OnPreReport()
    begin
        ComInfo.Get();
        ShowDate := FORMAT(Today, 0, '<Closing><Day,2>/<Month,2>/<Year4>');
        ShowTime := LSVIPRepFunction.AVTimeFormat(Time);
    end;

    var
        LSVIPRepFunction: Codeunit "PLSR_Report Function";
        ComInfo: Record "Company Information";
        ItemTB: Record Item;
        StoreTB: Record "LSC Store";
        POSTerminalTB: Record "LSC POS Terminal";
        TransHeaderTB: Record "LSC Transaction Header";
        MemberContactTB: Record "LSC Member Contact";
        MemberShipCardTB: Record "LSC Membership Card";
        RettailSetup: Record "LSC Retail Setup";
        TransHTb: Record "LSC Transaction Header";

        // Cache keys
        LastStoreNo: Code[20];
        LastItemNo: Code[20];
        LastMemberCardNo: Code[20];
        LastRefundReceiptNo: Text[30];
        LastRefundReceiptIsVoided: Boolean;

        ReceiptNo: Code[20];
        ShowTime: Text[50];
        ShowDate: Text[50];
        DateFilter: Text[100];
        TransType: Text[50];
        StoreFilter: Code[20];
        ItemNoFilter: Code[20];
        POSTerminalFilter: Code[20];
        CancelDocNo: Text[30];
        RefundDocNo: Text[30];
        PeriodDate: Text[100];
        ReportFilterText: Text[250];
        FromDateFilter: Date;
        TodateFilter: Date;
        FDateFilter: Date;
        Qty: Decimal;
        BaseQty: Decimal;
        UnitPrice: Decimal;
        Choose1Filter: Boolean;
        Choose2Filter: Boolean;
        RefundFilter: Option " ","Yes","No";
}
