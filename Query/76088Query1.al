query 50050 "PLSR_Q_DiscEntrySalesItem"
{
    QueryType = Normal;
    Caption = 'Discount/Coupon Entry Sales Item (Query)';
    OrderBy = ascending(Store_No), ascending(POS_Terminal_No), ascending(Transaction_No), ascending(Line_No);

    // AVPWDLSVIP 01/07/2026 > Improve Performance of VIP Report(76088) - น้องปอ
    elements
    {
        dataitem(DiscEntry; "LSC Trans. Discount Entry")
        {
            DataItemTableFilter = "Offer Type" = filter("Total Discount" | Coupon), "Discount Amount" = filter(<> 0);

            column(Store_No; "Store No.")
            { }
            column(POS_Terminal_No; "POS Terminal No.")
            { }
            column(Transaction_No; "Transaction No.")
            { }
            column(Line_No; "Line No.")
            { }
            column(Offer_No; "Offer No.")
            { }
            column(Offer_Type; "Offer Type")
            { }
            column(Discount_Amount; "Discount Amount")
            { }

            dataitem(TransHeader; "LSC Transaction Header")
            {
                DataItemLink = "Store No." = DiscEntry."Store No.", "POS Terminal No." = DiscEntry."POS Terminal No.", "Transaction No." = DiscEntry."Transaction No.";
                DataItemTableFilter = "Transaction Type" = const(Sales), "Entry Status" = filter(<> Voided);
                SqlJoinType = InnerJoin;

                column(Receipt_No; "Receipt No.")
                { }
                column(Header_Date; Date)
                { }

                dataitem(SalesEntry; "LSC Trans. Sales Entry")
                {
                    DataItemLink = "Store No." = DiscEntry."Store No.", "POS Terminal No." = DiscEntry."POS Terminal No.", "Transaction No." = DiscEntry."Transaction No.", "Line No." = DiscEntry."Line No.";
                    SqlJoinType = LeftOuterJoin;

                    column(Item_No; "Item No.")
                    { }

                    dataitem(ItemQ; Item)
                    {
                        DataItemLink = "No." = SalesEntry."Item No.";
                        SqlJoinType = LeftOuterJoin;

                        column(Item_Description; Description)
                        { }
                    }
                }
            }
        }
    }
    // C-AVPWDLSVIP 01/07/2026 > Improve Performance of VIP Report(76088) - น้องปอ
}