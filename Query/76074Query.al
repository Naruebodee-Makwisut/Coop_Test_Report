query 50058 "PLSR_Sales By Item"
{
    QueryType = Normal;
    OrderBy = ascending(Item_No, UOM, Price);

    elements
    {
        dataitem(TransSaleEntry; "LSC Trans. Sales Entry")
        {
            column(Item_No; "Item No.")
            { }
            column(UOM; "Unit of Measure")
            { }
            column(Price; Price)
            { }
            column(TransDate; Date)
            { }
            column(Store_No; "Store No.")
            { }
            column(Sum_Quantity; Quantity)
            {
                Method = Sum;
            }
            column(Sum_DiscountAmount; "Discount Amount")
            {
                Method = Sum;
            }
            column(Sum_TotalRoundedAmt; "Total Rounded Amt.")
            {
                Method = Sum;
            }
            column(Sum_UOMQuantity; "UOM Quantity")
            {
                Method = Sum;
            }
            column(Max_UOMPrice; "UOM Price")
            {
                Method = Max;
            }
        }
    }
}
