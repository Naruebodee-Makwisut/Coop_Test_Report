query 50054 "TEST_Store Sales VAT Query"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    OrderBy = ascending(Store_No_, POS_Terminal_No_, Transaction_No_);
    elements
    {
        dataitem(TransHeader; "LSC Transaction Header")
        {
            filter(Receipt_No_Filter; "Receipt No.") { }
            filter(Entry_Status_Filter; "Entry Status") { }
            filter(Date_Filter; "Date") { }
            filter(Store_Filter; "Store No.") { }

            column(Store_No_; "Store No.") { }
            column(POS_Terminal_No_; "POS Terminal No.") { }
            column(Transaction_No_; "Transaction No.") { }
            column(Receipt_No_; "Receipt No.") { }
            column(Date; "Date") { }
            column(Net_Amount; "Net Amount") { }
            column(Gross_Amount; "Gross Amount") { }
            column(Rounded; Rounded) { }
            column(Sale_Is_Return_Sale; "Sale Is Return Sale") { }
            column(PLSLC_Refund_Full_VAT_No_; "PLSLC_Refund Full VAT No.") { }
            column(PLSLC_Full_VAT_No_; "PLSLC_Full VAT No.") { }
            column(PLSLC_POS_Customer_Name; "PLSLC_POS Customer Name") { }
            column(PLSLC_POS_Customer_Name_2; "PLSLC_POS Customer Name 2") { }
            column(PLSLC_POS_Customer_Name_3; "PLSLC_POS Customer Name 3") { }
            column(PLSLC_POS_VAT_Registration; "PLSLC_POS VAT Registration") { }
            column(PLSLC_POS_Branch_No_; "PLSLC_POS Branch No.") { }

            // ชั้นที่ 1: Join เข้ากับตาราง Store
            dataitem(Store; "LSC Store")
            {
                DataItemLink = "No." = TransHeader."Store No.";
                SqlJoinType = LeftOuterJoin;

                column(PLSLC_Branch_No_; "PLSLC_Branch No.") { }
                column(PLSLC_Show_Full_Vat_At_HQ; "PLSLC_Show Full Vat At HQ") { }
                column(Store_Address; Address) { }
                column(Store_Address_2; "Address 2") { }
                column(PLSLC_Address_3; "PLSLC_Address 3") { }
                column(PLSLC_Address_4; "PLSLC_Address 4") { }
                column(PLSLC_Address_5; "PLSLC_Address 5") { }

                // ชั้นที่ 2: ซ้อนอยู่ใต้ Store แต่ Link กลับไปหาตารางบนสุด (TransHeader)
                dataitem(POSTerminal; "LSC POS Terminal")
                {
                    DataItemLink = "No." = TransHeader."POS Terminal No.";
                    SqlJoinType = LeftOuterJoin;

                    column(PLSLC_POS_No_; "PLSLC_POS No.") { }
                }
            }
        }
    }
}