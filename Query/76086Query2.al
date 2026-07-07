query 50060 "PLSR Statement Line Qry"
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
            dataitem(StatementLine; "LSC Statement Line")
            {
                DataItemLink = "Statement No." = Statement."No.";

                column(TransAmount; "Trans. Amount")
                {
                    Method = Sum;
                }
            }
        }
    }
}
