query 50115 "PLSR_Active Member Q"
{
    Caption = 'Member Sales Summary';
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    OrderBy = ascending(MemberAccountNo, EntryDate);
    elements
    {
        dataitem(MemberSalesEntry; "LSC Member Sales Entry")
        {
            column(MemberAccountNo; "Member Account No.") { }
            column(EntryDate; "Date") { }
            column(DocumentNo; "Document No.") { }
            column(MemberClub; "Member Club") { }
            column(MemberScheme; "Member Scheme") { }
            column(MemberContactNo; "Member Contact No.") { }
            column(MemberCardNo; "Member Card No.") { }
            column(SumGrossAmount; "Gross Amount")
            {
                Method = Sum;
            }
            dataitem(LSC_Member_Contact; "LSC Member Contact")
            {
                DataItemLink = "Account No." = MemberSalesEntry."Member Account No.";
                filter(Search_Name; "Search Name") { }
                filter(Mobile_Phone_No_; "Mobile Phone No.") { }
                filter(PLSWS_ID_Card_No_; "PLSWS_ID Card No.") { }
                column(Account_No_; "Account No.") { }
                column(MemberName; Name) { }
                column(SchemeCode; "Scheme Code") { }
            }
        }
    }
}