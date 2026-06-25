query 50400 "PLSR_MemberSalesHistory Q"
{
    Caption = 'MemberSalesHistory';
    QueryType = Normal;
    OrderBy = ascending(Member_Account_No_, Store_No_, Date, Entry_No_, Line_No_);

    elements
    {
        dataitem(MemberSalesEntry; "LSC Member Sales Entry")
        {
            filter(DateFilter; Date) { }

            column(Entry_No_; "Entry No.") { }
            column(Line_No_; "Line No.") { }
            column(Member_Contact_No_; "Member Contact No.") { }
            column(Member_Account_No_; "Member Account No.") { }
            column(Store_No_; "Store No.") { }
            column(Document_No_; "Document No.") { }
            column(Date; Date) { }
            column(Transaction_No_; "Transaction No.") { }
            column(Item_No_; "Item No.") { }
            column(Description; Description) { }
            column(Item_Variant_Code; "Item Variant Code") { }
            column(Discount_Amount; "Discount Amount") { }

            // JOIN: LSC Member Contact — เพื่อให้ filter Search Name / Mobile / ID Card ได้
            // ใช้ InnerJoin เพราะต้องการเฉพาะ Sales Entry ที่มี Contact จริงๆ
            dataitem(MemberContact; "LSC Member Contact")
            {
                DataItemLink = "Contact No." = MemberSalesEntry."Member Contact No.";
                SqlJoinType = InnerJoin;

                // filter fields ตรงกับ RequestFilterFields ของ dummy dataitem ใน Report
                filter(SearchNameFilter; "Search Name") { }
                filter(MobilePhoneNoFilter; "Mobile Phone No.") { }
                filter(IDCardNoFilter; "PLSWS_ID Card No.") { }

                // JOIN: LSC Member Account — ดึง Description
                dataitem(MemberAccount; "LSC Member Account")
                {
                    DataItemLink = "No." = MemberSalesEntry."Member Account No.";
                    SqlJoinType = LeftOuterJoin;

                    column(Member_Account_Description; Description) { }

                    // JOIN: LSC Transaction Header — ดึง Sale Is Return Sale
                    dataitem(TransactionHeader; "LSC Transaction Header")
                    {
                        DataItemLink =
                            "Transaction No." = MemberSalesEntry."Transaction No.",
                            "Store No." = MemberSalesEntry."Store No.",
                            "Receipt No." = MemberSalesEntry."Document No.";
                        SqlJoinType = LeftOuterJoin;

                        column(Sale_Is_Return_Sale; "Sale Is Return Sale") { }

                        // JOIN: LSC Trans. Sales Entry — ดึง UOM / QTY / Price
                        dataitem(TransSalesEntry; "LSC Trans. Sales Entry")
                        {
                            DataItemLink =
                                "Transaction No." = MemberSalesEntry."Transaction No.",
                                "Store No." = MemberSalesEntry."Store No.",
                                "Receipt No." = MemberSalesEntry."Document No.",
                                "Line No." = MemberSalesEntry."Line No.";
                            SqlJoinType = LeftOuterJoin;

                            column(UOM_TransSale; "Unit of Measure") { }
                            column(UOM_Quantity; "UOM Quantity") { }
                            column(Quantity; Quantity) { }
                            column(UOM_Price; "UOM Price") { }
                            column(Price; Price) { }

                            // JOIN: Sales Shipment Line — fallback UOM / QTY / Price
                            dataitem(SalesShipmentLine; "Sales Shipment Line")
                            {
                                DataItemLink =
                                    "Order No." = MemberSalesEntry."Document No.",
                                    "Line No." = MemberSalesEntry."Line No.",
                                    "No." = MemberSalesEntry."Item No.";
                                SqlJoinType = LeftOuterJoin;

                                column(Shipment_UOM; "Unit of Measure") { }
                                column(Shipment_Quantity; Quantity) { }
                                column(Shipment_Unit_Price; "Unit Price") { }
                            }
                        }
                    }
                }
            }
        }
    }

    trigger OnBeforeOpen()
    begin
    end;
}
