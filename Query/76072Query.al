query 50040 "PLSR Sales By Prod Query"
{
    // query 76072 "PLSR_Sales By ProdGroup Q"
    // {
    Caption = 'Sales Report By Product Group';
    QueryType = Normal;
    OrderBy = ascending(Store_No_, POS_Terminal_No_, Transaction_No_, Line_No_);

    elements
    {
        dataitem(TransSale; "LSC Trans. Sales Entry")
        {
            filter(DateFilter; Date) { }
            filter(StoreNoFilter; "Store No.") { }
            filter(ItemNoFilter; "Item No.") { }
            filter(ProductGroupFilter; "Retail Product Code") { }

            column(Store_No_; "Store No.") { }
            column(POS_Terminal_No_; "POS Terminal No.") { }
            column(Transaction_No_; "Transaction No.") { }
            column(Line_No_; "Line No.") { }
            column(Variant_Code; "Variant Code") { }
            column(Retail_Product_Code; "Retail Product Code") { }
            column(Item_Category_Code; "Item Category Code") { }
            column(Receipt_No_; "Receipt No.") { }
            column(Date_; Date) { }
            column(Item_No_; "Item No.") { }
            column(Unit_of_Measure; "Unit of Measure") { }
            column(Quantity; Quantity) { }
            column(UOM_Quantity; "UOM Quantity") { }
            column(Price; Price) { }
            column(UOM_Price; "UOM Price") { }
            column(Discount_Amount; "Discount Amount") { }
            column(Return_No_Sale; "Return No Sale") { }

            dataitem(TransHeaderTB; "LSC Transaction Header")
            {
                DataItemLink = "Store No." = TransSale."Store No.",
                               "POS Terminal No." = TransSale."POS Terminal No.",
                               "Transaction No." = TransSale."Transaction No.";
                SqlJoinType = InnerJoin;
                column(Transaction_Type; "Transaction Type") { }

                dataitem(ItemTB; Item)
                {
                    DataItemLink = "No." = TransSale."Item No.";
                    SqlJoinType = LeftOuterJoin;
                    column(Item_Description; Description) { }
                    column(Item_Description2; "Description 2") { }

                    dataitem(RetailProdGroupTB; "LSC Retail Product Group")
                    {
                        DataItemLink = Code = TransSale."Retail Product Code",
                                       "Item Category Code" = TransSale."Item Category Code";
                        SqlJoinType = LeftOuterJoin;
                        column(ProdGroup_Description; Description) { }

                        dataitem(ItemVariantTB; "Item Variant")
                        {
                            DataItemLink = "Item No." = TransSale."Item No.",
                                           Code = TransSale."Variant Code";
                            SqlJoinType = LeftOuterJoin;
                            column(Variant_Description; Description) { }
                        }
                    }
                }
            }
        }
    }
}