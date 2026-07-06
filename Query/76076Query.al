query 50041 "PLSR_Sales By Sale Staff Q"
{
    Caption = 'Sales Report By Sale Staff';
    QueryType = Normal;
    OrderBy = ascending(Store_No_, POS_Terminal_No_, Transaction_No_, Line_No_);

    elements
    {
        dataitem(TransSale; "LSC Trans. Sales Entry")
        {
            filter(DateFilter; Date) { }
            filter(StoreNoFilter; "Store No.") { }
            filter(ItemNoFilter; "Item No.") { }
            filter(SaleStaffFilter; "Sales Staff") { }
            filter(ReturnNoSaleFilter; "Return No Sale") { }

            column(Store_No_; "Store No.") { }
            column(POS_Terminal_No_; "POS Terminal No.") { }
            column(Transaction_No_; "Transaction No.") { }
            column(Line_No_; "Line No.") { }
            column(Variant_Code; "Variant Code") { }
            column(Receipt_No_; "Receipt No.") { }
            column(Date_; Date) { }
            column(Item_No_; "Item No.") { }
            column(Sales_Staff; "Sales Staff") { }
            column(Unit_of_Measure; "Unit of Measure") { }
            column(Quantity; Quantity) { }
            column(UOM_Quantity; "UOM Quantity") { }
            column(Price; Price) { }
            column(UOM_Price; "UOM Price") { }
            column(Discount_Amount; "Discount Amount") { }
            column(Return_No_Sale; "Return No Sale") { }

            dataitem(TransHeaderTB; "LSC Transaction Header")
            {
                DataItemLink = "Store No." = TransSale."Store No.",
                               "POS Terminal No." = TransSale."POS Terminal No.",
                               "Transaction No." = TransSale."Transaction No.";
                SqlJoinType = InnerJoin;
                column(Transaction_Type; "Transaction Type") { }
                column(Sale_Is_Return_Sale; "Sale Is Return Sale") { }
                column(Retrieved_From_Receipt_No; "Retrieved from Receipt No.") { }
                column(Refund_Receipt_No; "Refund Receipt No.") { }
                column(Ref_Refund_Receipt_No; "PLSPOS_Ref. Refund Receipt No.") { }
                column(Member_Card_No; "Member Card No.") { }

                dataitem(ItemTB; Item)
                {
                    DataItemLink = "No." = TransSale."Item No.";
                    SqlJoinType = LeftOuterJoin;
                    column(Item_Description; Description) { }
                    column(Item_Description2; "Description 2") { }

                    dataitem(StaffTB; "LSC Staff")
                    {
                        DataItemLink = ID = TransSale."Sales Staff";
                        SqlJoinType = LeftOuterJoin;
                        column(Staff_First_Name; "First Name") { }
                        column(Staff_Last_Name; "Last Name") { }

                        dataitem(MemberShipCardTB; "LSC Membership Card")
                        {
                            DataItemLink = "Card No." = TransHeaderTB."Member Card No.";
                            SqlJoinType = LeftOuterJoin;
                            column(Card_No; "Card No.") { }
                            column(Account_No; "Account No.") { }
                            column(Contact_No; "Contact No.") { }

                            dataitem(MemberContactTB; "LSC Member Contact")
                            {
                                DataItemLink = "Account No." = MemberShipCardTB."Account No.",
                                               "Contact No." = MemberShipCardTB."Contact No.";
                                SqlJoinType = LeftOuterJoin;
                                column(Member_Name; Name) { }
                                column(Member_Name2; "Name 2") { }
                            }
                        }
                    }
                }
            }
        }
    }
}