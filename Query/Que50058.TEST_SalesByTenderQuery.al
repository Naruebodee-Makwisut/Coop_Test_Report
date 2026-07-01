query 50058 "TEST_Sales By Tender Query"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(TransPayEntry; "LSC Trans. Payment Entry")
        {
            filter(Date_Filter; "Date") { }
            filter(Store_Filter; "Store No.") { }
            filter(POS_Terminal_Filter; "POS Terminal No.") { }
            filter(Tender_Type_Filter; "Tender Type") { }
            filter(Staff_Filter; "Staff ID") { }
            filter(Change_Line_Filter; "Change Line") { }
            column(Store_No_; "Store No.") { }
            column(POS_Terminal_No_; "POS Terminal No.") { }
            column(Transaction_No_; "Transaction No.") { }
            column(Line_No_; "Line No.") { }
            column(Tender_Type_; "Tender Type") { }
            column(Receipt_No_; "Receipt No.") { }
            column(Date; "Date") { }
            column(Amount_Tendered; "Amount Tendered") { }
            column(Change_Line; "Change Line") { }
            column(Safe_type; "Safe type") { }

            dataitem(TenderType; "LSC Tender Type")
            {
                DataItemLink = "Store No." = TransPayEntry."Store No.", "Code" = TransPayEntry."Tender Type";
                SqlJoinType = LeftOuterJoin;

                column(Tender_Description; Description) { }
                column(PLSPOS_Infocode_Card_No_; "PLSPOS_Infocode Card No.") { }
                dataitem(TransHeader; "LSC Transaction Header")
                {
                    DataItemLink = "Store No." = TransPayEntry."Store No.", "POS Terminal No." = TransPayEntry."POS Terminal No.", "Transaction No." = TransPayEntry."Transaction No.";
                    SqlJoinType = LeftOuterJoin;

                    column(Member_Card_No_; "Member Card No.") { }
                }
            }
        }
    }
}