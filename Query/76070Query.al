query 50048 "PLSR_Sales Report By DivisionQ"
{
    QueryType = Normal;
    Caption = 'POS Sales By Division Query';
    OrderBy = ascending(Store_No, Date, Receipt_No, Line_No);

    elements
    {
        dataitem(TransSale; "LSC Trans. Sales Entry")
        {
            filter(DateFilter; "Date") { }
            filter(StoreNoFilter; "Store No.") { }
            filter(ItemNoFilter; "Item No.") { }
            filter(DivisionCodeFilter; "Division Code") { }

            column(Store_No; "Store No.") { }
            column(POS_Terminal_No; "POS Terminal No.") { }
            column(Transaction_No; "Transaction No.") { }
            column(Line_No; "Line No.") { }
            column(Variant_Code; "Variant Code") { }
            column(Receipt_No; "Receipt No.") { }
            column(Date; "Date") { }
            column(Item_No; "Item No.") { }
            column(Unit_of_Measure; "Unit of Measure") { }
            column(UOM_Quantity; "UOM Quantity") { }
            column(Quantity; Quantity) { }
            column(UOM_Price; "UOM Price") { }
            column(Price; Price) { }
            column(Discount_Amount; "Discount Amount") { }
            column(Return_No_Sale; "Return No Sale") { }
            column(Division_Code; "Division Code") { }

            dataitem(TransHeaderTB; "LSC Transaction Header")
            {
                DataItemLink = "Store No." = TransSale."Store No.",
                               "POS Terminal No." = TransSale."POS Terminal No.",
                               "Transaction No." = TransSale."Transaction No.";
                SqlJoinType = LeftOuterJoin;

                column(Transaction_Type; "Transaction Type") { }

                dataitem(ItemTB; Item)
                {
                    DataItemLink = "No." = TransSale."Item No.";
                    SqlJoinType = LeftOuterJoin;

                    column(Item_Description; Description) { }
                    column(Item_Description_2; "Description 2") { }
                    column(LSC_Division_Code; "LSC Division Code") { }

                    dataitem(DivisonTB; "LSC Division")
                    {
                        DataItemLink = Code = TransSale."Division Code";
                        SqlJoinType = LeftOuterJoin;

                        column(Division_Description; Description) { }
                    }
                }
            }
        }
    }
}