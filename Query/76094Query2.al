query 50043 "Member Point Entry Q"
{
    // ดึง Point ในช่วง Period แยกตาม Entry Type เพื่อให้ Report แยก
    // PointEarned / PointRedeemed / PointAdjust / PointExpire
    Caption = 'MemberBalancePoint Period';
    QueryType = Normal;
    OrderBy = ascending(Account_No_, Entry_Type);

    elements
    {
        dataitem(Member_Point_Entry; "LSC Member Point Entry")
        {
            filter(Account_No; "Account No.") { }
            filter(Date; Date) { }

            column(Account_No_; "Account No.") { }
            column(Entry_Type; "Entry Type") { }
            column(Points; Points)
            {
                Method = Sum;
            }
        }
    }
}
