report 50117 "PLSR_Check_Statement at HQ"
{
    Caption = 'Check Statement at HQ';
    DefaultLayout = RDLC;
    RDLCLayout = './ReportLayouts/Rep50117_CheckStatementatHQ.rdl';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem(Store; "LSC Store")
        {
            DataItemTableView = SORTING("No.") WHERE("Store Type" = CONST(Store));
            column(No_; "No.") { }
            column(Name; Name) { }
            column(CountStatement; CountStatement) { }
            column(SumSaleAmt; SumSaleAmt) { }
            column(SumTransAmt; SumTransAmt) { }
            column(CountTransSale; CountTransSale) { }
            column(CountTransSaleStatus; CountTransSaleStatus) { }
            column(CheckAmount; CheckAmount) { }
            column(CheckSaleCount; CheckSaleCount) { }

            trigger OnAfterGetRecord()
            begin
                CLEAR(CountStatement);
                CLEAR(SumSaleAmt);
                CLEAR(SumTransAmt);
                CLEAR(CheckAmount);
                CLEAR(CountTransSale);
                CLEAR(CountTransSaleStatus);
                CLEAR(CheckSaleCount);

                // --- Statement: count via plain Record.COUNT() (already cheap, no CalcFields involved) ---
                CLEAR(Statement);
                Statement.SETRANGE("Store No.", "No.");
                Statement.SETRANGE("Posting Date", StartDate, EndDate);
                Statement.SetLoadFields("No.");
                CountStatement := Statement.COUNT();

                // --- Sales/VAT Amount: aggregated by SQL via Query (avoids per-record CALCFIELDS) ---
                HeaderQry.SetRange(StoreNo, "No.");
                HeaderQry.SetRange(PostingDate, StartDate, EndDate);
                if HeaderQry.Open() then begin
                    while HeaderQry.Read() do
                        SumSaleAmt += (HeaderQry.SalesAmount + HeaderQry.VATAmount) * -1;
                    HeaderQry.Close();
                end;

                // --- Statement Line: Trans. Amount, aggregated by SQL via Query (avoids nested loop) ---
                LineQry.SetRange(StoreNo, "No.");
                LineQry.SetRange(PostingDate, StartDate, EndDate);
                if LineQry.Open() then begin
                    while LineQry.Read() do
                        SumTransAmt += LineQry.TransAmount;
                    LineQry.Close();
                end;

                IF ((SumSaleAmt <> 0) AND (SumTransAmt <> 0)) AND (SumSaleAmt = SumTransAmt) THEN
                    CheckAmount := TRUE;

                // --- Trans. Sales Entry: count via plain Record.COUNT() ---
                CLEAR(TransSalesEntry);
                TransSalesEntry.SETRANGE("Store No.", Store."No.");
                TransSalesEntry.SETRANGE(Date, StartDate, EndDate);
                TransSalesEntry.SetLoadFields("Transaction No.");
                CountTransSale := TransSalesEntry.COUNT();

                // --- Trans. Sales Entry Status: count via plain Record.COUNT() ---
                CLEAR(TransSalesEntryStatus);
                TransSalesEntryStatus.SETRANGE("Store No.", Store."No.");
                TransSalesEntryStatus.SETRANGE(Date, StartDate, EndDate);
                TransSalesEntryStatus.SetLoadFields("Transaction No.");
                CountTransSaleStatus := TransSalesEntryStatus.COUNT();

                IF ((CountTransSale <> 0) AND (CountTransSaleStatus <> 0)) AND (CountTransSale = CountTransSaleStatus) THEN
                    CheckSaleCount := TRUE;
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
                    field("Start Date"; StartDate)
                    {
                        Caption = 'Start Date';
                        ApplicationArea = All;
                    }
                    field("End Date"; EndDate)
                    {
                        Caption = 'End Date';
                        ApplicationArea = All;
                    }
                }
            }
        }
    }

    var
        HeaderQry: Query "PLSR Statement Header Qry";
        LineQry: Query "PLSR Statement Line Qry";
        Statement: Record "LSC Statement";
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        TransSalesEntryStatus: Record "LSC Trans. Sales Entry Status";
        CountStatement: Integer;
        SumSaleAmt: Decimal;
        SumTransAmt: Decimal;
        CountTransSale: Integer;
        CountTransSaleStatus: Integer;
        CheckAmount: Boolean;
        CheckSaleCount: Boolean;
        StartDate: Date;
        EndDate: Date;
}
