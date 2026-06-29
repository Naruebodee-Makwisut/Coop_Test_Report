query 50045 "PLSR_StoreStockILE_Q"
{
    QueryType = Normal;
    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            filter(Item_No; "Item No.") { }
            filter(Variant_Code; "Variant Code") { }
            filter(Posting_Date; "Posting Date") { }
            filter(Location_Code; "Location Code") { }
            filter(Lot_No; "Lot No.") { }

            column(Q_Item_No; "Item No.") { }
            column(Q_Variant_Code; "Variant Code") { }
            column(Sum_Remaining_Qty; "Remaining Quantity")
            {
                Method = Sum;
            }
            dataitem(ItemMaster; Item)
            {
                DataItemLink = "No." = ItemLedgerEntry."Item No.";

                filter(Item_Category; "Item Category Code") { }
                filter(Product_Group; "LSC Retail Product Code") { }
                filter(Division_Code; "LSC Division Code") { }
                filter(Is_Blocked; Blocked) { }

                column(Item_Desc; Description) { }
                column(Base_UOM; "Base Unit of Measure") { }
            }
        }
    }
}

query 50046 "PLSR_StoreStockTSE_Q"
{
    QueryType = Normal;
    elements
    {
        dataitem(TransSales; "LSC Trans. Sales Entry")
        {
            filter(Item_No; "Item No.") { }
            filter(Variant_Code; "Variant Code") { }
            filter(Date_Filter; Date) { }
            filter(Store_No; "Store No.") { }

            column(Q_Item_No; "Item No.") { }
            column(Q_Variant_Code; "Variant Code") { }
            column(Sum_Quantity; Quantity)
            {
                Method = Sum;
            }
            dataitem(ItemMaster; Item)
            {
                DataItemLink = "No." = TransSales."Item No.";

                filter(Item_Category; "Item Category Code") { }
                filter(Product_Group; "LSC Retail Product Code") { }
                filter(Division_Code; "LSC Division Code") { }
                filter(Is_Blocked; Blocked) { }

                column(Item_Desc; Description) { }
                column(Base_UOM; "Base Unit of Measure") { }
            }
        }
    }
}

query 50047 "PLSR_StoreStockTSES_Q"
{
    QueryType = Normal;
    elements
    {
        dataitem(TransSalesStatus; "LSC Trans. Sales Entry Status")
        {
            filter(Item_No; "Item No.") { }
            filter(Variant_Code; "Variant Code") { }
            filter(Date_Filter; Date) { }
            filter(Store_No; "Store No.") { }
            filter(Status; Status) { }
            filter(Lot_No; "Lot No.") { }

            column(Q_Item_No; "Item No.") { }
            column(Q_Variant_Code; "Variant Code") { }
            column(Sum_Quantity; Quantity)
            {
                Method = Sum;
            }
            dataitem(ItemMaster; Item)
            {
                DataItemLink = "No." = TransSalesStatus."Item No.";

                filter(Item_Category; "Item Category Code") { }
                filter(Product_Group; "LSC Retail Product Code") { }
                filter(Division_Code; "LSC Division Code") { }
                filter(Is_Blocked; Blocked) { }

                column(Item_Desc; Description) { }
                column(Base_UOM; "Base Unit of Measure") { }
            }
        }
    }
}