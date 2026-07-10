query 50061 "100 Top Spender"
{
    QueryType = Normal;
    elements
    {
        dataitem(Member_Sales_Entry; "LSC Member Sales Entry")
        {
            filter(Date_Filter; Date) { }
            column(Member_Account_No_; "Member Account No.") { }
            column(Member_Club; "Member Club") { }
            column(Member_Scheme; "Member Scheme") { }
            column(Total_Gross_Amount; "Gross Amount")
            {
                Method = Sum;
            }
        }
    }
}