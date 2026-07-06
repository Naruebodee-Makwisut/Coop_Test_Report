query 50051 "PLSR_Q_BenefitEntrySalesItem"
{
    QueryType = Normal;
    Caption = 'Discount Benefit Entry Sales Item (Query)';
    OrderBy = ascending(Store_No), ascending(POS_Terminal_No), ascending(Transaction_No), ascending(Line_No);

    // AVPWDLSVIP 01/07/2026 > Improve Performance of VIP Report(76088) - น้องปอ
    elements
    {
        dataitem(BenefitEntry; "LSC Trans. Disc. Benefit Entry")
        {
            DataItemTableFilter = "Offer Type" = const("Total Discount"), Type = filter(Item | Coupon);

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
            column(Benefit_Type; Type)
            { }
            column(Item_No; "No.")
            { }
            column(Benefit_Value; Value)
            { }
            column(Benefit_Quantity; Quantity)
            { }

            dataitem(TransHeader; "LSC Transaction Header")
            {
                DataItemLink = "Store No." = BenefitEntry."Store No.", "POS Terminal No." = BenefitEntry."POS Terminal No.", "Transaction No." = BenefitEntry."Transaction No.";
                DataItemTableFilter = "Transaction Type" = const(Sales), "Entry Status" = filter(<> Voided);
                SqlJoinType = InnerJoin;

                column(Receipt_No; "Receipt No.")
                { }
                column(Header_Date; Date)
                { }

                dataitem(ItemQ; Item)
                {
                    DataItemLink = "No." = BenefitEntry."No.";
                    SqlJoinType = LeftOuterJoin;

                    column(Item_Description; Description)
                    { }
                }
            }
        }
    }
    // C-AVPWDLSVIP 01/07/2026 > Improve Performance of VIP Report(76088) - น้องปอ
}