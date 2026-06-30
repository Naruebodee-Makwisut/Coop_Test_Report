query 50058 "TEST_Sales By Tender Query"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(TransPayEntry; "LSC Trans. Payment Entry")
        {
            // กำหนดช่อง Filter ท่อส่งข้อมูลจาก Report
            filter(Date_Filter; "Date") { }
            filter(Store_Filter; "Store No.") { }
            filter(POS_Terminal_Filter; "POS Terminal No.") { }
            filter(Tender_Type_Filter; "Tender Type") { }
            filter(Staff_Filter; "Staff ID") { }
            filter(Change_Line_Filter; "Change Line") { }

            // ดึงฟิลด์ที่ต้องการใช้จาก TransPayEntry
            column(Store_No_; "Store No.") { }
            column(POS_Terminal_No_; "POS Terminal No.") { }
            column(Transaction_No_; "Transaction No.") { }
            column(Line_No_; "Line No.") { }
            column(Tender_Type_; "Tender Type") { }
            column(Receipt_No_; "Receipt No.") { }
            column(Date; "Date") { }
            column(Amount_Tendered; "Amount Tendered") { }
            column(Change_Line; "Change Line") { }
            column(Safe_type; "Safe type") { }

            // ชั้นที่ 1: Join เข้ากับตาราง Tender Type เพื่อเอา Description
            dataitem(TenderType; "LSC Tender Type")
            {
                DataItemLink = "Store No." = TransPayEntry."Store No.", "Code" = TransPayEntry."Tender Type";
                SqlJoinType = LeftOuterJoin;

                column(Tender_Description; Description) { }
                column(PLSPOS_Infocode_Card_No_; "PLSPOS_Infocode Card No.") { }

                // ชั้นที่ 2: ซ้อนลงมาข้างล่าง แต่ดึง Link กลับไปที่ตารางบนสุด (TransPayEntry) เพื่อหา Header บิล
                dataitem(TransHeader; "LSC Transaction Header")
                {
                    DataItemLink = "Store No." = TransPayEntry."Store No.", "POS Terminal No." = TransPayEntry."POS Terminal No.", "Transaction No." = TransPayEntry."Transaction No.";
                    SqlJoinType = LeftOuterJoin;

                    column(Member_Card_No_; "Member Card No.") { }
                }
            }
        }
    }
}