query 50042 "PLSR_Member Point BF Q"
{

     // ดึง Point ก่อนช่วง (B/F) โดย SUM Points และ Remaining Points
    // grouping ตาม Account No. เพื่อให้ได้ยอด aggregate ต่อ Member
    Caption = 'MemberBalancePoint BF';
    QueryType = Normal;
    OrderBy = ascending(Account_No_);

    elements
    {
        dataitem(MemberPointEntry; "LSC Member Point Entry")
        {
            // filter วันที่จะถูก set จาก Report ก่อน Open() เสมอ
            filter(DateFilter; Date) { }
            filter(AccountNoFilter; "Account No.") { }

            // group by Account No. เพื่อ SUM per member
            column(Account_No_; "Account No.")
            {
                ColumnFilter = Account_No_ = filter(<> '');
            }
            column(Date;Date){}

            // SUM Points (ใช้คำนวณ PointBF)
            column(Total_Points; Points)
            {
                Method = Sum;
            }

            // SUM Remaining Points (เก็บไว้ใช้อ้างอิงถ้าต้องการในอนาคต)
            column(Total_Remaining_Points; "Remaining Points")
            {
                Method = Sum;
            }
        }
    }

    trigger OnBeforeOpen()
    begin
    end;
}
