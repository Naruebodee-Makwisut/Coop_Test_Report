query 50045 "PLSR_StoreStockILE_Q"
{
    Caption = 'Store Stock ILE';
    QueryType = Normal;

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            filter(Item_No_Filter; "Item No.") { }
            filter(Location_Code_Filter; "Location Code") { }
            filter(Posting_Date_Filter; "Posting Date") { }

            column(Item_No; "Item No.") { }
            column(Variant_Code; "Variant Code") { }
            column(Sum_Remaining_Quantity; "Remaining Quantity") { Method = Sum; }
        }
    }
}

query 50046 "PLSR_StoreStockTSE_Q"
{
    Caption = 'Store Stock TSE';
    QueryType = Normal;

    elements
    {
        dataitem(TransSalesEntry; "LSC Trans. Sales Entry")
        {
            filter(Item_No_Filter; "Item No.") { }
            filter(Store_No_Filter; "Store No.") { }
            filter(Date_Filter; Date) { }

            column(Item_No; "Item No.") { }
            column(Variant_Code; "Variant Code") { }
            column(Trans_Date; Date) { }
            column(Sum_Quantity; Quantity) { Method = Sum; }
        }
    }
}

query 50047 "PLSR_StoreStockTSES_Q"
{
    Caption = 'Store Stock TSES';
    QueryType = Normal;

    elements
    {
        dataitem(TransSalesEntryStatus; "LSC Trans. Sales Entry Status")
        {
            filter(Item_No_Filter; "Item No.") { }
            filter(Store_No_Filter; "Store No.") { }
            filter(Date_Filter; Date) { }
            filter(Status_Filter; Status) { }

            column(Item_No; "Item No.") { }
            column(Variant_Code; "Variant Code") { }
            column(Trans_Date; Date) { }
            column(Sum_Quantity; Quantity) { Method = Sum; }
        }
    }
}