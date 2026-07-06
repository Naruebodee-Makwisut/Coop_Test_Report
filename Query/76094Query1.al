query 50042 "Member Point BF Q"
{

     // ดึง Point ก่อนช่วง (B/F) โดย SUM Points และ Remaining Points
    // grouping ตาม Account No. เพื่อให้ได้ยอด aggregate ต่อ Member
    Caption = 'MemberBalancePoint BF';
    QueryType = Normal;
    OrderBy = ascending(Account_No_);

    elements
    {
        dataitem(Member_Point_Entry; "LSC Member Point Entry")
        {
            filter(Account_No; "Account No.") { }
            filter(Date; Date) { }

            column(Account_No_; "Account No.") { }
            column(Points; Points)
            {
                Method = Sum;
            }
        }
    }
}
