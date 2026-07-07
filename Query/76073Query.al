query 50053 "TEST_POS Sales Sum Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(TransSalesEntry; "LSC Trans. Sales Entry")
        {
            filter(Date_Filter; "Date") { }
            filter(Store_Filter; "Store No.") { }

            column(Item_No_; "Item No.")
            {
            }
            column(Sum_Quantity; Quantity)
            {
                Method = Sum;
            }
            column(Sum_Amount; "Total Rounded Amt.")
            {
                Method = Sum;
            }
        }
    }
}