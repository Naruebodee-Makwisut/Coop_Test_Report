query 50057 "POSSaleByTerm_Q"
{
    QueryType = Normal;

    // AVPWDLSVIP 03/07/2026 > Improve Performance of VIP Report(76075) - น้องปอ
    elements
    {
        dataitem(TransSale; "LSC Trans. Sales Entry")
        {
            column(StoreNo; "Store No.")
            { }
            column(POSTerminalNo; "POS Terminal No.")
            { }
            column(TransactionNo; "Transaction No.")
            { }
            column(LineNo; "Line No.")
            { }
            column(ReceiptNo; "Receipt No.")
            { }
            column(EntryDate; Date)
            { }
            column(ItemNo; "Item No.")
            { }
            column(VariantCode; "Variant Code")
            { }
            column(UnitOfMeasure; "Unit of Measure")
            { }
            column(UOMQuantity; "UOM Quantity")
            { }
            column(Quantity; Quantity)
            { }
            column(UOMPrice; "UOM Price")
            { }
            column(Price; Price)
            { }
            column(DiscountAmount; "Discount Amount")
            { }
            column(ReturnNoSale; "Return No Sale")
            { }

            dataitem(TransHeader; "LSC Transaction Header")
            {
                DataItemLink = "Store No." = TransSale."Store No.",
                               "POS Terminal No." = TransSale."POS Terminal No.",
                               "Transaction No." = TransSale."Transaction No.";
                SqlJoinType = LeftOuterJoin;

                column(HeaderTransactionType; "Transaction Type")
                { }
                column(HeaderSaleIsReturnSale; "Sale Is Return Sale")
                { }
                column(HeaderRetrievedFromReceiptNo; "Retrieved from Receipt No.")
                { }
                column(HeaderRefundReceiptNo; "Refund Receipt No.")
                { }
                column(HeaderMemberCardNo; "Member Card No.")
                { }
                column(HeaderRefRefundReceiptNo; "PLSPOS_Ref. Refund Receipt No.")
                { }
                column(HeaderTime; Time)
                { }
            }
        }
    }
    // C-AVPWDLSVIP 03/07/2026 > Improve Performance of VIP Report(76075) - น้องปอ
}
