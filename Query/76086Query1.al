query 50059 "PLSR Statement Header Qry"
{
    QueryType = Normal;

    elements
    {
        dataitem(Statement; "LSC Statement")
        {
            column(StoreNo; "Store No.")
            {
            }
            column(PostingDate; "Posting Date")
            {
            }
            column(SalesAmount; "Sales Amount")
            {
                Method = Sum;
            }
            column(VATAmount; "VAT Amount")
            {
                Method = Sum;
            }
        }
    }
}
