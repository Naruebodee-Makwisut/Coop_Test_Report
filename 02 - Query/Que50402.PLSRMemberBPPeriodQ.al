query 50402 "PLSR_MemberBPPeriod Q"
{
    // ดึง Point ในช่วง Period แยกตาม Entry Type เพื่อให้ Report แยก
    // PointEarned / PointRedeemed / PointAdjust / PointExpire
    Caption = 'MemberBalancePoint Period';
    QueryType = Normal;
    OrderBy = ascending(Account_No_, Entry_Type);

    elements
    {
        dataitem(MemberPointEntry; "LSC Member Point Entry")
        {
            filter(DateFilter; Date) { }
            filter(AccountNoFilter; "Account No.") { }

            // group by Account No. + Entry Type → ได้ Points SUM ต่อ type ต่อ member
            column(Account_No_; "Account No.")
            {
                ColumnFilter = Account_No_ = filter(<> '');
            }

            column(Entry_Type; "Entry Type") { }

            column(Total_Points; Points)
            {
                Method = Sum;
            }
        }
    }

    trigger OnBeforeOpen()
    begin
    end;
}
