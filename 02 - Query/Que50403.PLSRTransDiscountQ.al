query 50403 "PLSR_TransDiscount Q"
{
    Caption = 'Trans Discount Query';
    QueryType = Normal;
    OrderBy = ascending(Store_No_, POS_Terminal_No_, Transaction_No_, Line_No_);

    elements
    {
        dataitem(TransDiscEntry; "LSC Trans. Discount Entry")
        {
            filter(StoreFilter; "Store No.") { }
            filter(PosTerminalNoFilter; "POS Terminal No.") { }
            filter(TransactionNoFilter; "Transaction No.") { }
            filter(OfferNoFilter; "Offer No.") { }

            column(Store_No_; "Store No.") { }
            column(POS_Terminal_No_; "POS Terminal No.") { }
            column(Transaction_No_; "Transaction No.") { }
            column(Line_No_; "Line No.") { }
            column(Offer_No_; "Offer No.") { }
            column(Offer_Type_; "Offer Type") { }
            column(Discount_Amount_; "Discount Amount") { }

            // JOIN: Trans. Sales Entry → ดึง Item No.
            dataitem(TransSalesEntry; "LSC Trans. Sales Entry")
            {
                DataItemLink =
                    "Store No." = TransDiscEntry."Store No.",
                    "POS Terminal No." = TransDiscEntry."POS Terminal No.",
                    "Transaction No." = TransDiscEntry."Transaction No.",
                    "Line No." = TransDiscEntry."Line No.";
                SqlJoinType = LeftOuterJoin;

                column(Item_No_; "Item No.") { }

                // JOIN: Item → ดึง Description
                dataitem(ItemTB; Item)
                {
                    DataItemLink = "No." = TransSalesEntry."Item No.";
                    SqlJoinType = LeftOuterJoin;

                    column(Item_Description; Description) { }

                    // JOIN: LSC Barcodes → ดึง Barcode No.
                    dataitem(BarcodesTB; "LSC Barcodes")
                    {
                        DataItemLink = "Item No." = TransSalesEntry."Item No.";
                        SqlJoinType = LeftOuterJoin;

                        column(Barcode_No_; "Barcode No.") { }

                        // JOIN: LSC Periodic Discount → ดึง Description
                        // ไม่ JOIN CouponHeader เพราะ Offer Type อาจเป็น Coupon
                        // → จัดการ Coupon Description ด้วย Cache ใน Report แทน
                        dataitem(PeriodicDiscTB; "LSC Periodic Discount")
                        {
                            DataItemLink = "No." = TransDiscEntry."Offer No.";
                            SqlJoinType = LeftOuterJoin;

                            column(Periodic_Disc_Description; Description) { }
                        }
                    }
                }
            }
        }
    }

    trigger OnBeforeOpen()
    begin
    end;
}
