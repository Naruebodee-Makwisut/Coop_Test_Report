query 50055 "PLSR_StoreSalesVATAmt_Q"
{
    Caption = 'Store Sales VAT Amount';
    QueryType = Normal;

    // AVPWDLSVIP 30/06/2026 > Improve Performance of VIP Report(76082) - น้องปอ
    elements
    {
        dataitem(TransactionHeader; "LSC Transaction Header")
        {
            filter(Store_No; "Store No.") { }
            filter(POS_Terminal_No; "POS Terminal No.") { }
            filter(Date_Filter; Date) { }
            filter(Receipt_No; "Receipt No.") { }
            filter(Entry_Status; "Entry Status") { }
            filter(Full_VAT_No; "PLSLC_Full VAT No.") { }
            filter(Refund_Full_VAT_No; "PLSLC_Refund Full VAT No.") { }

            column(Sum_Net_Amount; "Net Amount")
            {
                Method = Sum;
            }
            column(Sum_Gross_Amount; "Gross Amount")
            {
                Method = Sum;
            }
        }
    }
    // C-AVPWDLSVIP 30/06/2026 > Improve Performance of VIP Report(76082) - น้องปอ
}
