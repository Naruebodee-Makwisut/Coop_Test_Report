query 50049 "PLSR_SalesReportByItemCateQ"
{
    Caption = 'POS Sales Report By Item Category Query';
    QueryType = Normal;

    elements
    {
        dataitem(TransSale; "LSC Trans. Sales Entry")
        {
            filter(DateFilter; "Date") { }
            filter(StoreNoFilter; "Store No.") { }
            filter(ItemNoFilter; "Item No.") { }
            filter(ItemCategoryFilter; "Item Category Code") { }

            column(Store_No; "Store No.") { }
            column(POS_Terminal_No; "POS Terminal No.") { }
            column(Transaction_No; "Transaction No.") { }
            column(Line_No; "Line No.") { }
            column(Variant_Code; "Variant Code") { }
            column(Item_Category_Code; "Item Category Code") { }
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

                    dataitem(ItemCateTB; "Item Category")
                    {
                        DataItemLink = Code = TransSale."Item Category Code";
                        SqlJoinType = LeftOuterJoin;

                        column(Category_Description; Description) { }
                    }
                }
            }
        }
    }
}