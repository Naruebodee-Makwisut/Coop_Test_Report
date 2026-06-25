query 50051 "PLSR_TransBenefit Q"
{
    Caption = 'Trans Benefit Query';
    QueryType = Normal;
    OrderBy = ascending(Store_No_, POS_Terminal_No_, Transaction_No_, Line_No_);

    elements
    {
        dataitem(TransBenefitEntry; "LSC Trans. Disc. Benefit Entry")
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
            column(No_; "No.") { }
            column(Quantity_; Quantity) { }
            column(Value_; Value) { }
            column(Variant_Code_; "Variant Code") { }
            column(Type_; Type) { }

            // JOIN: Item → ดึง Description
            dataitem(ItemTB; Item)
            {
                DataItemLink = "No." = TransBenefitEntry."No.";
                SqlJoinType = LeftOuterJoin;

                column(Item_Description; Description) { }

                // JOIN: LSC Barcodes → ดึง Barcode No.
                dataitem(BarcodesTB; "LSC Barcodes")
                {
                    DataItemLink = "Item No." = TransBenefitEntry."No.";
                    SqlJoinType = LeftOuterJoin;

                    column(Barcode_No_; "Barcode No.") { }

                    // JOIN: LSC Periodic Discount → ดึง Description
                    dataitem(PeriodicDiscTB; "LSC Periodic Discount")
                    {
                        DataItemLink = "No." = TransBenefitEntry."Offer No.";
                        SqlJoinType = LeftOuterJoin;

                        column(Periodic_Disc_Description; Description) { }
                    }
                }
            }
        }
    }

    trigger OnBeforeOpen()
    begin
    end;
}
