query 50058 "PLSR_Sales By Item"
{
    QueryType = Normal;
    OrderBy = ascending(Item_No, UOM, Price);

    elements
    {
        dataitem(TransSaleEntry; "LSC Trans. Sales Entry")
        {
            // Grouping dimensions we actually want in the final output
            column(Item_No; "Item No.")
            { }
            column(UOM; "Unit of Measure")
            { }
            column(Price; Price)
            { }

            // Filter-only dimensions. NOTE: because this query has aggregate (Sum/Max)
            // columns below, these two plain columns automatically become extra GROUP BY
            // dimensions in the generated SQL - that's unavoidable in AL. It just means the
            // rows returned are grouped by Item/UOM/Price/Date/Store instead of only
            // Item/UOM/Price. The report code re-aggregates across Date/Store in memory
            // (single fast pass, no DB calls), so correctness is unaffected - only slightly
            // more rows come back from SQL than the strict minimum.
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
            // NOT aggregated on purpose - the original report takes this value from
            // whichever row FindSet() happened to land on first within the group, not a
            // sum/max/min. We preserve that "first row encountered" semantics on the AL
            // side (see PrecomputeRowData) rather than changing the meaning via SQL Max.
            column(UOM_Price; "UOM Price")
            { }
        }
    }
}
